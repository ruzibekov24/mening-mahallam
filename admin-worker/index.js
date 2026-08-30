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
  FieldDelete,
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

  // PATCH /api/banners/:id
  //
  // Partial update. `promo_banner_repository.dart` has no `updateBanner`
  // method of its own (only `createBanner`/`deleteBanner`), so this
  // mirrors `createBanner`'s field set instead — every field it accepts
  // is optionally patchable here (not just imageUrl/linkUrl/order).
  const bannerPatchMatch = pathname.match(/^\/api\/banners\/([^/]+)$/);
  if (method === 'PATCH' && bannerPatchMatch) {
    const id = bannerPatchMatch[1];
    const body = await safeJson(request);
    const fields = {};
    if (body?.imageUrl !== undefined) {
      if (typeof body.imageUrl !== 'string' || !body.imageUrl) {
        throw new HttpError(400, 'imageUrl must be a non-empty string');
      }
      fields.imageUrl = body.imageUrl;
    }
    if (body?.title !== undefined) {
      if (typeof body.title !== 'string' || !body.title) {
        throw new HttpError(400, 'title must be a non-empty string');
      }
      fields.title = body.title;
    }
    if (body?.description !== undefined) {
      if (typeof body.description !== 'string' || !body.description) {
        throw new HttpError(400, 'description must be a non-empty string');
      }
      fields.description = body.description;
    }
    if (body?.order !== undefined) {
      if (!Number.isInteger(body.order)) throw new HttpError(400, 'order must be an integer');
      fields.order = body.order;
    }
    if (body?.linkUrl !== undefined) fields.linkUrl = body.linkUrl;
    if (body?.attribution !== undefined) fields.attribution = body.attribution;
    if (Object.keys(fields).length === 0) {
      throw new HttpError(400, 'No updatable fields provided');
    }
    const existing = await getDoc(env, 'promoBanners', id);
    if (!existing) throw new HttpError(404, 'Banner not found');
    const updated = await patchDoc(env, 'promoBanners', id, fields);
    return jsonResponse({ banner: updated }, 200, env);
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

  // GET /api/announcements?mahallaId=X
  if (method === 'GET' && pathname === '/api/announcements') {
    const mahallaId = searchParams.get('mahallaId');
    const docs = await listMahallaSubcollection(env, 'announcements', mahallaId, 'createdAt');
    return jsonResponse({ announcements: docs }, 200, env);
  }

  // POST /api/announcements
  //
  // Matches lib/features/announcements/data/announcement_repository.dart's
  // `AnnouncementRepository.createAnnouncement`. `authorUid` is set to the
  // calling superAdmin's uid (the Dart model's `authorUid` field is
  // required/non-nullable, so this Worker never omits it).
  // `reactedUids` is intentionally never written here — new announcements
  // simply start with none (`Announcement.fromFirestore` already defaults
  // a missing `reactedUids` map to `{}`).
  if (method === 'POST' && pathname === '/api/announcements') {
    const body = await safeJson(request);
    if (!body || typeof body.mahallaId !== 'string' || !body.mahallaId) {
      throw new HttpError(400, 'mahallaId is required');
    }
    if (typeof body.title !== 'string' || !body.title) {
      throw new HttpError(400, 'title is required');
    }
    if (typeof body.body !== 'string' || !body.body) {
      throw new HttpError(400, 'body is required');
    }
    if (!['kommunal', 'xavfsizlik', 'umumiy'].includes(body.category)) {
      throw new HttpError(400, 'category must be one of "kommunal", "xavfsizlik", "umumiy"');
    }
    const fields = {
      title: body.title,
      body: body.body,
      category: body.category,
      authorUid: uid,
      createdAt: new Date(),
    };
    if (typeof body.imageUrl === 'string' && body.imageUrl) fields.imageUrl = body.imageUrl;
    const doc = await createDoc(env, `mahallas/${body.mahallaId}/announcements`, fields);
    doc.mahallaId = body.mahallaId;
    return jsonResponse({ announcement: doc }, 201, env);
  }

  // PATCH /api/announcements/:mahallaId/:id
  //
  // Partial update of title/body/category/imageUrl — never touches
  // `reactedUids`, which is only ever mutated by the mobile app's
  // reaction toggle (`AnnouncementRepository.toggleReaction`).
  const announcementPatchMatch = pathname.match(/^\/api\/announcements\/([^/]+)\/([^/]+)$/);
  if (method === 'PATCH' && announcementPatchMatch) {
    const [, mahallaId, id] = announcementPatchMatch;
    const body = await safeJson(request);
    const fields = {};
    if (body?.title !== undefined) {
      if (typeof body.title !== 'string' || !body.title) {
        throw new HttpError(400, 'title must be a non-empty string');
      }
      fields.title = body.title;
    }
    if (body?.body !== undefined) {
      if (typeof body.body !== 'string' || !body.body) {
        throw new HttpError(400, 'body must be a non-empty string');
      }
      fields.body = body.body;
    }
    if (body?.category !== undefined) {
      if (!['kommunal', 'xavfsizlik', 'umumiy'].includes(body.category)) {
        throw new HttpError(400, 'category must be one of "kommunal", "xavfsizlik", "umumiy"');
      }
      fields.category = body.category;
    }
    if (body?.imageUrl !== undefined) fields.imageUrl = body.imageUrl;
    if (Object.keys(fields).length === 0) {
      throw new HttpError(400, 'No updatable fields provided');
    }
    const existing = await getDoc(env, `mahallas/${mahallaId}/announcements`, id);
    if (!existing) throw new HttpError(404, 'Announcement not found');
    const updated = await patchDoc(env, `mahallas/${mahallaId}/announcements`, id, fields);
    updated.mahallaId = mahallaId;
    return jsonResponse({ announcement: updated }, 200, env);
  }

  // DELETE /api/announcements/:mahallaId/:id
  const announcementDeleteMatch = pathname.match(/^\/api\/announcements\/([^/]+)\/([^/]+)$/);
  if (method === 'DELETE' && announcementDeleteMatch) {
    const [, mahallaId, id] = announcementDeleteMatch;
    await deleteDoc(env, `mahallas/${mahallaId}/announcements`, id);
    return jsonResponse({ ok: true }, 200, env);
  }

  // GET /api/events?mahallaId=X
  if (method === 'GET' && pathname === '/api/events') {
    const mahallaId = searchParams.get('mahallaId');
    const docs = await listMahallaSubcollection(env, 'events', mahallaId, 'dateTime');
    return jsonResponse({ events: docs }, 200, env);
  }

  // POST /api/events
  //
  // Matches lib/features/announcements/data/event_repository.dart's
  // `EventRepository.createEvent`. `participantsCount` always starts at
  // 0 (mirrors the Dart method — it's incremented elsewhere, not
  // settable at creation).
  if (method === 'POST' && pathname === '/api/events') {
    const body = await safeJson(request);
    if (!body || typeof body.mahallaId !== 'string' || !body.mahallaId) {
      throw new HttpError(400, 'mahallaId is required');
    }
    if (typeof body.title !== 'string' || !body.title) {
      throw new HttpError(400, 'title is required');
    }
    if (typeof body.location !== 'string' || !body.location) {
      throw new HttpError(400, 'location is required');
    }
    const dateTime = parseIsoDate(body.dateTime);
    if (!dateTime) throw new HttpError(400, 'dateTime is required (ISO 8601 string)');
    const fields = {
      title: body.title,
      dateTime,
      location: body.location,
      participantsCount: 0,
      createdAt: new Date(),
      authorUid: uid,
    };
    const doc = await createDoc(env, `mahallas/${body.mahallaId}/events`, fields);
    doc.mahallaId = body.mahallaId;
    return jsonResponse({ event: doc }, 201, env);
  }

  // PATCH /api/events/:mahallaId/:id
  //
  // Partial update of title/dateTime/location — matches
  // `EventRepository.updateEvent` (which doesn't touch
  // `participantsCount` either).
  const eventPatchMatch = pathname.match(/^\/api\/events\/([^/]+)\/([^/]+)$/);
  if (method === 'PATCH' && eventPatchMatch) {
    const [, mahallaId, id] = eventPatchMatch;
    const body = await safeJson(request);
    const fields = {};
    if (body?.title !== undefined) {
      if (typeof body.title !== 'string' || !body.title) {
        throw new HttpError(400, 'title must be a non-empty string');
      }
      fields.title = body.title;
    }
    if (body?.location !== undefined) {
      if (typeof body.location !== 'string' || !body.location) {
        throw new HttpError(400, 'location must be a non-empty string');
      }
      fields.location = body.location;
    }
    if (body?.dateTime !== undefined) {
      const dateTime = parseIsoDate(body.dateTime);
      if (!dateTime) throw new HttpError(400, 'dateTime must be a valid ISO 8601 string');
      fields.dateTime = dateTime;
    }
    if (Object.keys(fields).length === 0) {
      throw new HttpError(400, 'No updatable fields provided');
    }
    const existing = await getDoc(env, `mahallas/${mahallaId}/events`, id);
    if (!existing) throw new HttpError(404, 'Event not found');
    const updated = await patchDoc(env, `mahallas/${mahallaId}/events`, id, fields);
    updated.mahallaId = mahallaId;
    return jsonResponse({ event: updated }, 200, env);
  }

  // DELETE /api/events/:mahallaId/:id
  const eventDeleteMatch = pathname.match(/^\/api\/events\/([^/]+)\/([^/]+)$/);
  if (method === 'DELETE' && eventDeleteMatch) {
    const [, mahallaId, id] = eventDeleteMatch;
    await deleteDoc(env, `mahallas/${mahallaId}/events`, id);
    return jsonResponse({ ok: true }, 200, env);
  }

  // GET /api/requests?mahallaId=X&status=Y
  if (method === 'GET' && pathname === '/api/requests') {
    const mahallaId = searchParams.get('mahallaId');
    const status = searchParams.get('status');
    const where = status
      ? {
          fieldFilter: {
            field: { fieldPath: 'status' },
            op: 'EQUAL',
            value: { stringValue: status },
          },
        }
      : undefined;
    const docs = await listMahallaSubcollection(env, 'requests', mahallaId, 'createdAt', where);
    return jsonResponse({ requests: docs }, 200, env);
  }

  // POST /api/requests/:mahallaId/:id/status  { status: "yangi" | "jarayonda" | "yakunlandi" }
  const requestStatusMatch = pathname.match(/^\/api\/requests\/([^/]+)\/([^/]+)\/status$/);
  if (method === 'POST' && requestStatusMatch) {
    const [, mahallaId, id] = requestStatusMatch;
    const body = await safeJson(request);
    const status = body?.status;
    if (!['yangi', 'jarayonda', 'yakunlandi'].includes(status)) {
      throw new HttpError(400, 'status must be one of "yangi", "jarayonda", "yakunlandi"');
    }
    const existing = await getDoc(env, `mahallas/${mahallaId}/requests`, id);
    if (!existing) throw new HttpError(404, 'Request not found');
    const updated = await patchDoc(env, `mahallas/${mahallaId}/requests`, id, { status });
    updated.mahallaId = mahallaId;
    return jsonResponse({ request: updated }, 200, env);
  }

  // GET /api/polls?mahallaId=X
  //
  // Returns each poll's raw doc plus a computed `results` summary
  // (per-option vote counts + total voters) so the frontend doesn't have
  // to replicate the `votes` map -> counts logic from
  // lib/features/polls/data/poll_repository.dart's `Poll.voteCounts` /
  // `Poll.totalVotes` getters.
  if (method === 'GET' && pathname === '/api/polls') {
    const mahallaId = searchParams.get('mahallaId');
    const docs = await listMahallaSubcollection(env, 'polls', mahallaId, 'createdAt');
    const polls = docs.map((doc) => ({ ...doc, results: computePollResults(doc) }));
    return jsonResponse({ polls }, 200, env);
  }

  // POST /api/polls
  //
  // Matches lib/features/polls/data/poll_repository.dart's
  // `PollRepository.createPoll`. `votes` always starts empty (`{}`) —
  // the Dart repository is the only writer that ever touches it after
  // creation (via `vote`).
  if (method === 'POST' && pathname === '/api/polls') {
    const body = await safeJson(request);
    if (!body || typeof body.mahallaId !== 'string' || !body.mahallaId) {
      throw new HttpError(400, 'mahallaId is required');
    }
    if (typeof body.question !== 'string' || !body.question) {
      throw new HttpError(400, 'question is required');
    }
    if (!Array.isArray(body.options) || body.options.length < 2 ||
        !body.options.every((o) => typeof o === 'string' && o)) {
      throw new HttpError(400, 'options must be an array of at least 2 non-empty strings');
    }
    const closesAt = body.closesAt === undefined || body.closesAt === null
      ? null
      : parseIsoDate(body.closesAt);
    if (body.closesAt !== undefined && body.closesAt !== null && !closesAt) {
      throw new HttpError(400, 'closesAt must be a valid ISO 8601 string or null');
    }
    const fields = {
      question: body.question,
      options: body.options,
      authorUid: uid,
      createdAt: new Date(),
      votes: {},
      allowMultiple: body.allowMultiple === true,
      isAnonymous: body.isAnonymous === true,
      closesAt,
    };
    const doc = await createDoc(env, `mahallas/${body.mahallaId}/polls`, fields);
    doc.mahallaId = body.mahallaId;
    doc.results = computePollResults(doc);
    return jsonResponse({ poll: doc }, 201, env);
  }

  // PATCH /api/polls/:mahallaId/:id
  //
  // Partial update of question/options/allowMultiple/isAnonymous/
  // closesAt. Deliberately never touches `votes` — that's mutated only
  // by the mobile app's voting flow (`PollRepository.vote`). Note this
  // differs from `PollRepository.updatePoll`, which resets `votes` to
  // `{}` whenever options change (to avoid stale option indexes) — this
  // endpoint leaves that judgment call to the caller/frontend instead.
  const pollPatchMatch = pathname.match(/^\/api\/polls\/([^/]+)\/([^/]+)$/);
  if (method === 'PATCH' && pollPatchMatch) {
    const [, mahallaId, id] = pollPatchMatch;
    const body = await safeJson(request);
    const fields = {};
    if (body?.question !== undefined) {
      if (typeof body.question !== 'string' || !body.question) {
        throw new HttpError(400, 'question must be a non-empty string');
      }
      fields.question = body.question;
    }
    if (body?.options !== undefined) {
      if (!Array.isArray(body.options) || body.options.length < 2 ||
          !body.options.every((o) => typeof o === 'string' && o)) {
        throw new HttpError(400, 'options must be an array of at least 2 non-empty strings');
      }
      fields.options = body.options;
    }
    if (body?.allowMultiple !== undefined) fields.allowMultiple = body.allowMultiple === true;
    if (body?.isAnonymous !== undefined) fields.isAnonymous = body.isAnonymous === true;
    if (body?.closesAt !== undefined) {
      if (body.closesAt === null) {
        fields.closesAt = null;
      } else {
        const closesAt = parseIsoDate(body.closesAt);
        if (!closesAt) throw new HttpError(400, 'closesAt must be a valid ISO 8601 string or null');
        fields.closesAt = closesAt;
      }
    }
    if (Object.keys(fields).length === 0) {
      throw new HttpError(400, 'No updatable fields provided');
    }
    const existing = await getDoc(env, `mahallas/${mahallaId}/polls`, id);
    if (!existing) throw new HttpError(404, 'Poll not found');
    const updated = await patchDoc(env, `mahallas/${mahallaId}/polls`, id, fields);
    updated.mahallaId = mahallaId;
    updated.results = computePollResults(updated);
    return jsonResponse({ poll: updated }, 200, env);
  }

  // DELETE /api/polls/:mahallaId/:id
  const pollDeleteMatch = pathname.match(/^\/api\/polls\/([^/]+)\/([^/]+)$/);
  if (method === 'DELETE' && pollDeleteMatch) {
    const [, mahallaId, id] = pollDeleteMatch;
    await deleteDoc(env, `mahallas/${mahallaId}/polls`, id);
    return jsonResponse({ ok: true }, 200, env);
  }

  // GET /api/service-ads?mahallaId=X
  if (method === 'GET' && pathname === '/api/service-ads') {
    const mahallaId = searchParams.get('mahallaId');
    const docs = await listMahallaSubcollection(env, 'serviceAds', mahallaId, 'createdAt');
    return jsonResponse({ serviceAds: docs }, 200, env);
  }

  // POST /api/service-ads
  //
  // Matches lib/features/ads/data/service_ad_repository.dart's
  // `ServiceAdRepository.createAd`. Note: the real doc schema is just
  // title/description/phone/ownerName/activeUntil/createdAt — there is
  // no `category` or `weeklyPrice` field stored per-doc (`weeklyPrice`
  // is a static price constant in the Dart repository, not per-ad
  // data), despite what earlier planning assumed. `durationDays`
  // (optional, default 7 — matches `ServiceAdRepository.defaultDuration`)
  // controls `activeUntil = now + durationDays`.
  if (method === 'POST' && pathname === '/api/service-ads') {
    const body = await safeJson(request);
    if (!body || typeof body.mahallaId !== 'string' || !body.mahallaId) {
      throw new HttpError(400, 'mahallaId is required');
    }
    if (typeof body.title !== 'string' || !body.title) {
      throw new HttpError(400, 'title is required');
    }
    if (typeof body.description !== 'string' || !body.description) {
      throw new HttpError(400, 'description is required');
    }
    if (typeof body.phone !== 'string' || !body.phone) {
      throw new HttpError(400, 'phone is required');
    }
    if (typeof body.ownerName !== 'string' || !body.ownerName) {
      throw new HttpError(400, 'ownerName is required');
    }
    const durationDays = Number.isFinite(body.durationDays) ? body.durationDays : 7;
    const activeUntil = new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000);
    const fields = {
      title: body.title,
      description: body.description,
      phone: body.phone,
      ownerName: body.ownerName,
      createdAt: new Date(),
      activeUntil,
    };
    const doc = await createDoc(env, `mahallas/${body.mahallaId}/serviceAds`, fields);
    doc.mahallaId = body.mahallaId;
    return jsonResponse({ serviceAd: doc }, 201, env);
  }

  // PATCH /api/service-ads/:mahallaId/:id
  //
  // Partial update of title/description/phone/ownerName, plus optional
  // `durationDays` to extend/replace `activeUntil` from now (mirrors
  // `ServiceAdRepository.extendAd`'s "extend from max(now, current)"
  // logic when `extendFromCurrent` is true, or set outright otherwise).
  const serviceAdPatchMatch = pathname.match(/^\/api\/service-ads\/([^/]+)\/([^/]+)$/);
  if (method === 'PATCH' && serviceAdPatchMatch) {
    const [, mahallaId, id] = serviceAdPatchMatch;
    const body = await safeJson(request);
    const fields = {};
    if (body?.title !== undefined) {
      if (typeof body.title !== 'string' || !body.title) {
        throw new HttpError(400, 'title must be a non-empty string');
      }
      fields.title = body.title;
    }
    if (body?.description !== undefined) {
      if (typeof body.description !== 'string' || !body.description) {
        throw new HttpError(400, 'description must be a non-empty string');
      }
      fields.description = body.description;
    }
    if (body?.phone !== undefined) {
      if (typeof body.phone !== 'string' || !body.phone) {
        throw new HttpError(400, 'phone must be a non-empty string');
      }
      fields.phone = body.phone;
    }
    if (body?.ownerName !== undefined) {
      if (typeof body.ownerName !== 'string' || !body.ownerName) {
        throw new HttpError(400, 'ownerName must be a non-empty string');
      }
      fields.ownerName = body.ownerName;
    }
    if (body?.durationDays !== undefined) {
      if (!Number.isFinite(body.durationDays)) {
        throw new HttpError(400, 'durationDays must be a number');
      }
      const existingAd = await getDoc(env, `mahallas/${mahallaId}/serviceAds`, id);
      if (!existingAd) throw new HttpError(404, 'Service ad not found');
      const current = existingAd.activeUntil ? new Date(existingAd.activeUntil) : null;
      const now = new Date();
      const base = body.extendFromCurrent && current && current > now ? current : now;
      fields.activeUntil = new Date(base.getTime() + body.durationDays * 24 * 60 * 60 * 1000);
    }
    if (Object.keys(fields).length === 0) {
      throw new HttpError(400, 'No updatable fields provided');
    }
    const existing = await getDoc(env, `mahallas/${mahallaId}/serviceAds`, id);
    if (!existing) throw new HttpError(404, 'Service ad not found');
    const updated = await patchDoc(env, `mahallas/${mahallaId}/serviceAds`, id, fields);
    updated.mahallaId = mahallaId;
    return jsonResponse({ serviceAd: updated }, 200, env);
  }

  // DELETE /api/service-ads/:mahallaId/:id
  const serviceAdDeleteMatch = pathname.match(/^\/api\/service-ads\/([^/]+)\/([^/]+)$/);
  if (method === 'DELETE' && serviceAdDeleteMatch) {
    const [, mahallaId, id] = serviceAdDeleteMatch;
    await deleteDoc(env, `mahallas/${mahallaId}/serviceAds`, id);
    return jsonResponse({ ok: true }, 200, env);
  }

  // GET /api/services?mahallaId=X
  //
  // Matches lib/features/services/data/service_repository.dart's
  // `LocalService`/`ServiceRepository` — the admin-curated local
  // service-provider directory ("Xizmatlar", e.g. plumber/electrician),
  // distinct from the paid `serviceAds` classifieds above.
  if (method === 'GET' && pathname === '/api/services') {
    const mahallaId = searchParams.get('mahallaId');
    const docs = await listMahallaSubcollection(env, 'services', mahallaId, 'createdAt');
    return jsonResponse({ services: docs }, 200, env);
  }

  // POST /api/services
  //
  // Matches `ServiceRepository.createService`. `authorUid` is set to
  // the calling superAdmin's uid.
  if (method === 'POST' && pathname === '/api/services') {
    const body = await safeJson(request);
    if (!body || typeof body.mahallaId !== 'string' || !body.mahallaId) {
      throw new HttpError(400, 'mahallaId is required');
    }
    if (typeof body.name !== 'string' || !body.name) {
      throw new HttpError(400, 'name is required');
    }
    if (!SERVICE_CATEGORIES.includes(body.category)) {
      throw new HttpError(400, `category must be one of ${SERVICE_CATEGORIES.join(', ')}`);
    }
    if (typeof body.phone !== 'string' || !body.phone) {
      throw new HttpError(400, 'phone is required');
    }
    if (typeof body.description !== 'string' || !body.description) {
      throw new HttpError(400, 'description is required');
    }
    const fields = {
      name: body.name,
      category: body.category,
      phone: body.phone,
      description: body.description,
      authorUid: uid,
      createdAt: new Date(),
    };
    const doc = await createDoc(env, `mahallas/${body.mahallaId}/services`, fields);
    doc.mahallaId = body.mahallaId;
    return jsonResponse({ service: doc }, 201, env);
  }

  // PATCH /api/services/:mahallaId/:id
  //
  // Partial update of name/category/phone/description — matches
  // `ServiceRepository.updateService` (which doesn't touch `authorUid`
  // or `createdAt` either).
  const servicePatchMatch = pathname.match(/^\/api\/services\/([^/]+)\/([^/]+)$/);
  if (method === 'PATCH' && servicePatchMatch) {
    const [, mahallaId, id] = servicePatchMatch;
    const body = await safeJson(request);
    const fields = {};
    if (body?.name !== undefined) {
      if (typeof body.name !== 'string' || !body.name) {
        throw new HttpError(400, 'name must be a non-empty string');
      }
      fields.name = body.name;
    }
    if (body?.category !== undefined) {
      if (!SERVICE_CATEGORIES.includes(body.category)) {
        throw new HttpError(400, `category must be one of ${SERVICE_CATEGORIES.join(', ')}`);
      }
      fields.category = body.category;
    }
    if (body?.phone !== undefined) {
      if (typeof body.phone !== 'string' || !body.phone) {
        throw new HttpError(400, 'phone must be a non-empty string');
      }
      fields.phone = body.phone;
    }
    if (body?.description !== undefined) {
      if (typeof body.description !== 'string' || !body.description) {
        throw new HttpError(400, 'description must be a non-empty string');
      }
      fields.description = body.description;
    }
    if (Object.keys(fields).length === 0) {
      throw new HttpError(400, 'No updatable fields provided');
    }
    const existing = await getDoc(env, `mahallas/${mahallaId}/services`, id);
    if (!existing) throw new HttpError(404, 'Service not found');
    const updated = await patchDoc(env, `mahallas/${mahallaId}/services`, id, fields);
    updated.mahallaId = mahallaId;
    return jsonResponse({ service: updated }, 200, env);
  }

  // DELETE /api/services/:mahallaId/:id
  const serviceDeleteMatch = pathname.match(/^\/api\/services\/([^/]+)\/([^/]+)$/);
  if (method === 'DELETE' && serviceDeleteMatch) {
    const [, mahallaId, id] = serviceDeleteMatch;
    await deleteDoc(env, `mahallas/${mahallaId}/services`, id);
    return jsonResponse({ ok: true }, 200, env);
  }

  // GET /api/users?search=X
  //
  // Firestore REST doesn't support arbitrary substring search, so this
  // does the standard Firestore "prefix range" trick
  // (`field >= search AND field < search + ''`) against either
  // `phone` or `firstName`, picked by whether `search` looks numeric.
  // This means **exact-prefix-match only**, case-sensitive, and only
  // against the start of one field — not a full substring/fuzzy search.
  if (method === 'GET' && pathname === '/api/users') {
    const search = searchParams.get('search');
    if (!search) throw new HttpError(400, 'search is required');
    const field = /^[+\d][\d\s-]*$/.test(search) ? 'phone' : 'firstName';
    const structuredQuery = {
      from: [{ collectionId: 'users' }],
      where: {
        compositeFilter: {
          op: 'AND',
          filters: [
            {
              fieldFilter: {
                field: { fieldPath: field },
                op: 'GREATER_THAN_OR_EQUAL',
                value: { stringValue: search },
              },
            },
            {
              fieldFilter: {
                field: { fieldPath: field },
                op: 'LESS_THAN',
                value: { stringValue: search + '' },
              },
            },
          ],
        },
      },
      orderBy: [{ field: { fieldPath: field }, direction: 'ASCENDING' }],
      limit: 50,
    };
    const docs = await runQuery(env, structuredQuery);
    return jsonResponse({ users: docs, searchedField: field }, 200, env);
  }

  // POST /api/users/:uid/role  { role: "citizen" | "staff" | "rais" | "superAdmin" }
  //
  // **Security-relevant, deliberate**: `firestore.rules` never allows the
  // mobile client to grant `superAdmin` (see the comment on `UserRole` in
  // lib/features/home/data/home_repository.dart) — but this Worker's
  // service-account credentials bypass Firestore rules entirely (same as
  // the Admin SDK), so this endpoint technically CAN grant it. That's
  // treated as intentional here: a superAdmin acting through this
  // trusted admin panel promoting someone else to superAdmin is a
  // legitimate admin action; the client-side rule exists to stop a
  // compromised/malicious mobile client from self-granting the role, not
  // to stop the admin backend itself. See README "Assumptions/TODOs" if
  // this should be reconsidered (e.g. requiring a second confirmation
  // step, or disallowing superAdmin grants here too).
  const userRoleMatch = pathname.match(/^\/api\/users\/([^/]+)\/role$/);
  if (method === 'POST' && userRoleMatch) {
    const uidToUpdate = userRoleMatch[1];
    const body = await safeJson(request);
    const role = body?.role;
    if (!['citizen', 'staff', 'rais', 'superAdmin'].includes(role)) {
      throw new HttpError(400, 'role must be one of "citizen", "staff", "rais", "superAdmin"');
    }
    const existing = await getDoc(env, 'users', uidToUpdate);
    if (!existing) throw new HttpError(404, 'User not found');
    const updated = await patchDoc(env, 'users', uidToUpdate, { role });
    return jsonResponse({ user: updated }, 200, env);
  }

  // POST /api/users/:uid/premium/grant  { months?: number }
  //
  // Direct grant, separate from the premiumRequests approve/reject flow
  // above — for use from a user-search/management UI (e.g. comping a
  // user premium without them having filed a payment request). Mirrors
  // `PremiumRepository.grantPremium` exactly: extends the existing
  // `premiumUntil` if it's still in the future, else starts from now;
  // `subscriptionPeriod` (30 days) * months.
  const premiumGrantMatch = pathname.match(/^\/api\/users\/([^/]+)\/premium\/grant$/);
  if (method === 'POST' && premiumGrantMatch) {
    const uidToGrant = premiumGrantMatch[1];
    const body = await safeJson(request);
    const months = body?.months !== undefined ? body.months : 1;
    if (!Number.isInteger(months) || months < 1) {
      throw new HttpError(400, 'months must be a positive integer');
    }
    const existing = await getDoc(env, 'users', uidToGrant);
    if (!existing) throw new HttpError(404, 'User not found');
    const updated = await grantUserPremium(env, uidToGrant, months);
    return jsonResponse({ user: updated }, 200, env);
  }

  // POST /api/users/:uid/premium/revoke
  //
  // Mirrors `PremiumRepository.revokePremium` exactly: deletes the
  // `premiumUntil` field entirely (via Firestore's field-delete, not
  // setting it to null) — matches the Dart `FieldValue.delete()` call.
  const premiumRevokeMatch = pathname.match(/^\/api\/users\/([^/]+)\/premium\/revoke$/);
  if (method === 'POST' && premiumRevokeMatch) {
    const uidToRevoke = premiumRevokeMatch[1];
    const existing = await getDoc(env, 'users', uidToRevoke);
    if (!existing) throw new HttpError(404, 'User not found');
    const updated = await patchDoc(env, 'users', uidToRevoke, { premiumUntil: FieldDelete });
    return jsonResponse({ user: updated }, 200, env);
  }

  throw new HttpError(404, 'Not found');
}

/** Valid `ServiceCategory` values — mirrors `ServiceCategoryX.firestoreValue`
 * in lib/features/services/data/service_repository.dart. */
const SERVICE_CATEGORIES = ['santexnik', 'elektrik', 'duradgor', 'tozalash', 'qurilish', 'boshqa'];

/** Parses an ISO 8601 date string into a `Date`, or returns `null` if invalid. */
function parseIsoDate(value) {
  if (typeof value !== 'string' || !value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

/**
 * Grants/extends premium on a user doc — the exact same shape as
 * `PremiumRepository.grantPremium`: extends the existing `premiumUntil`
 * if it's still in the future, otherwise starts from now, by
 * `subscriptionPeriod` (30 days) * months. Shared by both the
 * premium-request approval flow and the direct grant endpoint.
 */
async function grantUserPremium(env, uid, months) {
  const SUBSCRIPTION_PERIOD_MS = 30 * 24 * 60 * 60 * 1000; // matches Dart's subscriptionPeriod
  const userDoc = await getDoc(env, 'users', uid);
  const currentPremiumUntil = userDoc?.premiumUntil ? new Date(userDoc.premiumUntil) : null;
  const now = new Date();
  const base = currentPremiumUntil && currentPremiumUntil > now ? currentPremiumUntil : now;
  const until = new Date(base.getTime() + SUBSCRIPTION_PERIOD_MS * months);
  return patchDoc(env, 'users', uid, { premiumUntil: until });
}

async function safeJson(request) {
  try {
    return await request.json();
  } catch {
    return null;
  }
}

/**
 * Lists a `mahallas/{mahallaId}/{collectionId}` subcollection.
 *
 * If `mahallaId` is given, queries just that mahalla's subcollection
 * (`parentPath = mahallas/{mahallaId}`). If omitted, runs a Firestore
 * *collection group* query (`allDescendants: true`) across every
 * mahalla's subcollection of that name, at the documents root — same
 * pattern as `computeAndStoreStats`'s "active requests" count. Results
 * are ordered by `orderByField` descending, newest first, and each doc
 * carries a `mahallaId` field either way.
 */
async function listMahallaSubcollection(env, collectionId, mahallaId, orderByField, where) {
  const structuredQuery = {
    from: [{ collectionId, ...(mahallaId ? {} : { allDescendants: true }) }],
    ...(where ? { where } : {}),
    orderBy: [{ field: { fieldPath: orderByField }, direction: 'DESCENDING' }],
  };
  if (mahallaId) {
    const docs = await runQuery(env, structuredQuery, `mahallas/${mahallaId}`);
    return docs.map((doc) => ({ ...doc, mahallaId }));
  }
  return runQuery(env, structuredQuery, '', { includeMahallaId: true });
}

/**
 * Computes per-option vote counts + total voter count from a poll doc's
 * `votes` map (`uid -> [optionIndex, ...]`), mirroring
 * `Poll.voteCounts` / `Poll.totalVotes` in
 * lib/features/polls/data/poll_repository.dart. Returns the raw doc
 * unmodified elsewhere — this is purely additive.
 */
function computePollResults(pollDoc) {
  const options = Array.isArray(pollDoc.options) ? pollDoc.options : [];
  const votes = pollDoc.votes && typeof pollDoc.votes === 'object' ? pollDoc.votes : {};
  const voteCounts = new Array(options.length).fill(0);
  let totalVotes = 0;
  for (const selected of Object.values(votes)) {
    const indexes = Array.isArray(selected) ? selected : [];
    if (indexes.length > 0) totalVotes += 1;
    for (const optionIndex of indexes) {
      if (Number.isInteger(optionIndex) && optionIndex >= 0 && optionIndex < voteCounts.length) {
        voteCounts[optionIndex] += 1;
      }
    }
  }
  return { voteCounts, totalVotes };
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
