// Mening Mahallam — super-admin dashboard API.
//
// Pure REST JSON API (no UI). Every route except `/health` requires a
// Firebase ID token (`Authorization: Bearer <token>`) belonging to a user
// whose Firestore `users/{uid}.role == 'superAdmin'` — see lib/auth.js.
//
// All Firestore access goes through the REST API using a Google OAuth2
// access token minted from a service account (lib/googleAuth.js), since
// Workers can't use the Firebase Admin SDK (it's Node-only). This mirrors
// what `lib/features/*/data/*_repository.dart` does client-side, so
// documents this Worker writes have the exact shape the Flutter app
// expects (see per-route comments below for the source repository file
// each route's writes were matched against).

import { requireSuperAdmin } from './lib/auth.js';
import { corsHeaders, jsonResponse, handleOptions, HttpError } from './lib/http.js';
import {
  getDoc,
  listCollection,
  runQuery,
  runAggregationQuery,
  createDoc,
  patchDoc,
  deleteDoc,
} from './lib/firestore.js';
import { getStats, upsertStats } from './lib/supabase.js';

export default {
  async fetch(request, env, ctx) {
    const { pathname, searchParams } = new URL(request.url);

    if (request.method === 'OPTIONS') return handleOptions(env);

    if (pathname === '/health') {
      return jsonResponse({ ok: true }, 200, env);
    }

    try {
      // Every route below requires a verified superAdmin. `uid` is the
      // calling admin's Firebase uid, used e.g. as `reviewedBy`.
      const uid = await requireSuperAdmin(request, env);
      return await route(request, env, pathname, searchParams, uid);
    } catch (err) {
      if (err instanceof HttpError) {
        return jsonResponse({ error: err.message }, err.status, env);
      }
      // Unexpected error — never leak stack traces or internals.
      console.error(err);
      return jsonResponse({ error: 'Internal error' }, 500, env);
    }
  },

  /**
   * Recomputes aggregate stats and caches them into Supabase so
   * `GET /api/stats` can serve a cheap read. Runs every 30 minutes per
   * the `[triggers] crons` entry in wrangler.toml.
   */
  async scheduled(event, env, ctx) {
    ctx.waitUntil(computeAndStoreStats(env));
  },
};

async function route(request, env, pathname, searchParams, uid) {
  const method = request.method;

  // GET /api/stats
  if (method === 'GET' && pathname === '/api/stats') {
    const row = await getStats(env);
    if (!row) {
      return jsonResponse(
        {
          totalMahallas: 0,
          totalUsers: 0,
          totalActiveRequests: 0,
          totalPendingPremium: 0,
          updatedAt: null,
          note: 'Stats have not been computed yet — the cron job runs every 30 minutes.',
        },
        200,
        env,
      );
    }
    return jsonResponse(
      {
        totalMahallas: row.total_mahallas,
        totalUsers: row.total_users,
        totalActiveRequests: row.total_active_requests,
        totalPendingPremium: row.total_pending_premium,
        updatedAt: row.updated_at,
      },
      200,
      env,
    );
  }

  // GET /api/mahallas
  if (method === 'GET' && pathname === '/api/mahallas') {
    const docs = await listCollection(env, 'mahallas');
    return jsonResponse({ mahallas: docs }, 200, env);
  }

  // GET /api/premium-requests?status=tolandi
  //
  // NOTE: the Flutter app's PremiumRequestStatus enum
  // (lib/features/premium/data/premium_repository.dart) doesn't have a
  // literal "pending" value — the status awaiting a superAdmin decision
  // is `tolandi` ("paid, awaiting approval"). The frontend should pass
  // `status=tolandi` for the actionable queue. Any status value is
  // accepted and passed through as an equality filter; omit the query
  // param to list all requests.
  if (method === 'GET' && pathname === '/api/premium-requests') {
    const status = searchParams.get('status');
    const structuredQuery = {
      from: [{ collectionId: 'premiumRequests' }],
      ...(status
        ? {
            where: {
              fieldFilter: {
                field: { fieldPath: 'status' },
                op: 'EQUAL',
                value: { stringValue: status },
              },
            },
          }
        : {}),
      orderBy: [{ field: { fieldPath: 'createdAt' }, direction: 'DESCENDING' }],
    };
    const docs = await runQuery(env, structuredQuery);
    return jsonResponse({ premiumRequests: docs }, 200, env);
  }

  // POST /api/premium-requests/:id/approve
  const approveMatch = pathname.match(/^\/api\/premium-requests\/([^/]+)\/approve$/);
  if (method === 'POST' && approveMatch) {
    return jsonResponse(await approvePremiumRequest(env, approveMatch[1], uid), 200, env);
  }

  // POST /api/premium-requests/:id/reject
  const rejectMatch = pathname.match(/^\/api\/premium-requests\/([^/]+)\/reject$/);
  if (method === 'POST' && rejectMatch) {
    const body = await safeJson(request);
    return jsonResponse(
      await rejectPremiumRequest(env, rejectMatch[1], uid, body?.reason),
      200,
      env,
    );
  }

  // GET /api/banners
  if (method === 'GET' && pathname === '/api/banners') {
    const docs = await listCollection(env, 'promoBanners');
    return jsonResponse({ banners: docs }, 200, env);
  }

  // POST /api/banners
  //
  // Matches the schema written by
  // lib/features/banners/data/promo_banner_repository.dart#createBanner.
  // Image upload itself is out of scope here — the frontend must upload
  // to Supabase Storage (or wherever) itself and pass the resulting
  // `imageUrl`.
  if (method === 'POST' && pathname === '/api/banners') {
    const body = await safeJson(request);
    if (!body || typeof body.imageUrl !== 'string' || !body.imageUrl) {
      throw new HttpError(400, 'imageUrl is required');
    }
    if (typeof body.title !== 'string' || typeof body.description !== 'string') {
      throw new HttpError(400, 'title and description are required');
    }
    const fields = {
      imageUrl: body.imageUrl,
      title: body.title,
      description: body.description,
      order: Number.isInteger(body.order) ? body.order : 0,
      createdAt: new Date(),
    };
    if (typeof body.linkUrl === 'string' && body.linkUrl) fields.linkUrl = body.linkUrl;
    if (typeof body.attribution === 'string' && body.attribution) {
      fields.attribution = body.attribution;
    }
    const doc = await createDoc(env, 'promoBanners', fields);
    return jsonResponse({ banner: doc }, 201, env);
  }

  // DELETE /api/banners/:id
  const bannerDeleteMatch = pathname.match(/^\/api\/banners\/([^/]+)$/);
  if (method === 'DELETE' && bannerDeleteMatch) {
    await deleteDoc(env, 'promoBanners', bannerDeleteMatch[1]);
    return jsonResponse({ ok: true }, 200, env);
  }

  // GET /api/reports?status=pending
  //
  // Matches lib/features/moderation/data/report_repository.dart's
  // top-level `reports` collection. Its ReportStatus enum's values are
  // literally `pending` / `reviewed` / `dismissed`, so this lines up with
  // the assumed shape as-is — but double check against that file if it
  // has since changed.
  if (method === 'GET' && pathname === '/api/reports') {
    const status = searchParams.get('status');
    const structuredQuery = {
      from: [{ collectionId: 'reports' }],
      ...(status
        ? {
            where: {
              fieldFilter: {
                field: { fieldPath: 'status' },
                op: 'EQUAL',
                value: { stringValue: status },
              },
            },
          }
        : {}),
      orderBy: [{ field: { fieldPath: 'createdAt' }, direction: 'DESCENDING' }],
    };
    const docs = await runQuery(env, structuredQuery);
    return jsonResponse({ reports: docs }, 200, env);
  }

  // POST /api/reports/:id/resolve  { outcome: "reviewed" | "dismissed" }
  const resolveMatch = pathname.match(/^\/api\/reports\/([^/]+)\/resolve$/);
  if (method === 'POST' && resolveMatch) {
    const body = await safeJson(request);
    const outcome = body?.outcome;
    if (outcome !== 'reviewed' && outcome !== 'dismissed') {
      throw new HttpError(400, 'outcome must be "reviewed" or "dismissed"');
    }
    const reportId = resolveMatch[1];
    const existing = await getDoc(env, 'reports', reportId);
    if (!existing) throw new HttpError(404, 'Report not found');
    const updated = await patchDoc(env, 'reports', reportId, {
      status: outcome,
      reviewedAt: new Date(),
      reviewedBy: uid,
    });
    return jsonResponse({ report: updated }, 200, env);
  }

  throw new HttpError(404, 'Not found');
}

async function safeJson(request) {
  try {
    return await request.json();
  } catch {
    return null;
  }
}

/**
 * Approves a premium request: grants premium on the user's doc (mirrors
 * `PremiumRepository.grantPremium` — extends the existing `premiumUntil`
 * if it's still in the future, otherwise starts from now), then marks
 * the request `tasdiqlandi`.
 */
async function approvePremiumRequest(env, requestId, adminUid) {
  const request = await getDoc(env, 'premiumRequests', requestId);
  if (!request) throw new HttpError(404, 'Premium request not found');
  if (!request.uid) throw new HttpError(500, 'Premium request is missing uid');

  const months = Number.isInteger(request.months) ? request.months : 1;
  const SUBSCRIPTION_PERIOD_MS = 30 * 24 * 60 * 60 * 1000; // 30 days, matches Dart's subscriptionPeriod

  const userDoc = await getDoc(env, 'users', request.uid);
  const currentPremiumUntil = userDoc?.premiumUntil ? new Date(userDoc.premiumUntil) : null;
  const now = new Date();
  const base = currentPremiumUntil && currentPremiumUntil > now ? currentPremiumUntil : now;
  const until = new Date(base.getTime() + SUBSCRIPTION_PERIOD_MS * months);

  await patchDoc(env, 'users', request.uid, { premiumUntil: until });

  const updatedRequest = await patchDoc(env, 'premiumRequests', requestId, {
    status: 'tasdiqlandi',
    decidedAt: now,
    decidedBy: adminUid,
  });

  return { premiumRequest: updatedRequest };
}

/** Rejects a premium request — mirrors `PremiumRepository.rejectRequest`. */
async function rejectPremiumRequest(env, requestId, adminUid, reason) {
  const existing = await getDoc(env, 'premiumRequests', requestId);
  if (!existing) throw new HttpError(404, 'Premium request not found');

  const fields = {
    status: 'radEtildi',
    decidedAt: new Date(),
    decidedBy: adminUid,
  };
  if (typeof reason === 'string' && reason) fields.rejectReason = reason;

  const updated = await patchDoc(env, 'premiumRequests', requestId, fields);
  return { premiumRequest: updated };
}

/**
 * Computes the four dashboard aggregate counts via Firestore
 * aggregation (`count()`) queries and upserts them into Supabase.
 *
 * Requests live at `mahallas/{mahallaId}/requests/{requestId}` (see
 * lib/features/requests/data/requests_repository.dart), so "active
 * requests across all mahallas" requires a Firestore *collection group*
 * query (`allDescendants: true` on the `requests` collectionId) rather
 * than a per-mahalla loop.
 */
async function computeAndStoreStats(env) {
  try {
    const [totalMahallas, totalUsers, totalActiveRequests, totalPendingPremium] =
      await Promise.all([
        runAggregationQuery(env, { from: [{ collectionId: 'mahallas' }] }),
        runAggregationQuery(env, { from: [{ collectionId: 'users' }] }),
        runAggregationQuery(env, {
          from: [{ collectionId: 'requests', allDescendants: true }],
          // "Active" = not yet finished, i.e. status is 'yangi' or
          // 'jarayonda' (mirrors RequestStatus in requests_repository.dart
          // — the enum's only "closed" value is 'yakunlandi').
          where: {
            fieldFilter: {
              field: { fieldPath: 'status' },
              op: 'IN',
              value: {
                arrayValue: {
                  values: [{ stringValue: 'yangi' }, { stringValue: 'jarayonda' }],
                },
              },
            },
          },
        }),
        runAggregationQuery(env, {
          from: [{ collectionId: 'premiumRequests' }],
          // Awaiting-approval status — see the /api/premium-requests note.
          where: {
            fieldFilter: {
              field: { fieldPath: 'status' },
              op: 'EQUAL',
              value: { stringValue: 'tolandi' },
            },
          },
        }),
      ]);

    await upsertStats(env, {
      total_mahallas: totalMahallas,
      total_users: totalUsers,
      total_active_requests: totalActiveRequests,
      total_pending_premium: totalPendingPremium,
    });
  } catch (err) {
    // Cron failures shouldn't throw uncaught — just log; the next run
    // (30 min later) will retry, and /api/stats degrades gracefully to
    // serving the last-known values (or zeros if none exist yet).
    console.error('Stats aggregation failed:', err);
  }
}
