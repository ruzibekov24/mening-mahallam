# mahallam-admin-api

Backend API for the Mening Mahallam super-admin web dashboard. Cloudflare
Worker, no build step, no npm dependencies — pure Workers runtime APIs
(`fetch`, Web Crypto `SubtleCrypto`) for Firebase ID token verification,
Google service-account OAuth2, and Firestore/Supabase REST calls.

## Files

- `index.js` — routing, route handlers, the `scheduled()` cron handler.
- `lib/jwt.js` — RS256 sign/verify + PEM/DER helpers (no npm JWT library
  needed; includes a minimal ASN.1/DER walker to pull the public key out
  of an X.509 certificate for `importKey('spki', ...)`).
- `lib/firebaseAuth.js` — verifies Firebase ID tokens against Google's
  public certs (cached in a module-level variable per the certs'
  `Cache-Control: max-age`).
- `lib/googleAuth.js` — service-account JWT-bearer OAuth2 flow, caches
  the resulting access token in memory for its ~1hr lifetime.
- `lib/firestore.js` — Firestore REST client (get/list/query/aggregate/
  create/patch/delete), with encode/decode between plain JS values and
  Firestore's tagged `{stringValue: ...}` REST value format.
- `lib/supabase.js` — reads/upserts the single `admin_stats` row via
  Supabase PostgREST.
- `lib/auth.js` — `requireSuperAdmin()`: verifies the bearer token, then
  checks `users/{uid}.role == 'superAdmin'` in Firestore.
- `lib/http.js` — CORS headers, JSON responses, `HttpError`.
- `supabase-schema.sql` — the `admin_stats` table definition. Run once in
  the Supabase SQL editor.

## Setup (for you to run — not done by this agent)

**Secrets** (`wrangler secret put <NAME>`, run from `admin-worker/`):

- `FIREBASE_CLIENT_EMAIL` — the service account's `client_email` (from
  the Firebase service-account JSON you download from Firebase Console →
  Project Settings → Service Accounts).
- `FIREBASE_PRIVATE_KEY` — the service account's `private_key` (the PEM
  string, including `-----BEGIN/END PRIVATE KEY-----`). Both real
  newlines and `\n`-escaped newlines are handled, so paste it however
  your shell preserves it.
- `SUPABASE_SERVICE_ROLE_KEY` — from Supabase project `dsbnguwyokxcxfcbeaym`
  → Settings → API → `service_role` secret key. **Never** use the `anon`
  key here — this key bypasses Row Level Security.

**Non-secret vars** — already set in `wrangler.toml` `[vars]`:

- `FIREBASE_PROJECT_ID = "mahallam-d4a93"`
- `SUPABASE_PROJECT_REF = "dsbnguwyokxcxfcbeaym"`
- `ALLOWED_ORIGIN = "*"` — tighten to the real admin frontend origin
  (e.g. its Cloudflare Pages domain) once known; see the comment in
  `lib/http.js`.

**Supabase**: run `supabase-schema.sql` once in the Supabase SQL editor
for project `dsbnguwyokxcxfcbeaym`.

**Firestore rules**: the service account calls Firestore via a Google
OAuth2 access token with the `datastore` scope, which — for a service
account with the default Firebase Admin / Editor IAM role — bypasses
Firestore Security Rules entirely (same as the Admin SDK would). Make
sure the service account you create/use has at least the "Cloud
Datastore User" or "Firebase Admin" IAM role in the GCP project.

Then `wrangler deploy` from `admin-worker/`.

## Auth

Every route except `GET /health` requires:

```
Authorization: Bearer <firebase-id-token>
```

The token is verified (signature, `exp`, `iss`, `aud`) and its `sub`
(uid) is looked up in `users/{uid}`; the request is rejected unless
`role == 'superAdmin'`.

- `401` — missing/invalid/expired token.
- `403` — valid token, but not a superAdmin.
- `404` — route or resource not found.
- `500` — unexpected error (Firestore/Supabase down, etc.) — response
  body is a generic `{"error": "Internal error"}`, never a stack trace.

## API contract

All responses are JSON. All request bodies (where present) are JSON.

### `GET /health`

No auth required. `200 {"ok": true}`.

### `GET /api/stats`

Returns the cached aggregate stats (written by the cron job every 30
min). If the cron hasn't run yet, returns zeros/nulls with a `note`.

```json
{
  "totalMahallas": 12,
  "totalUsers": 340,
  "totalActiveRequests": 27,
  "totalPendingPremium": 3,
  "updatedAt": "2026-08-30T06:30:00.000Z"
}
```

### `GET /api/mahallas`

Lists all documents in the `mahallas` collection, unfiltered.

```json
{ "mahallas": [ { "id": "...", ...allFieldsFromTheDoc }, ... ] }
```

### `GET /api/premium-requests?status=<value>`

Lists `premiumRequests` docs, optionally filtered by exact `status`
match, newest first.

**Important**: the Flutter app's `PremiumRequestStatus` enum
(`lib/features/premium/data/premium_repository.dart`) does not have a
literal `"pending"` value. The status meaning "paid, awaiting
superAdmin approval" is `tolandi`. Valid values: `kutilmoqda` (created,
not yet paid), `tolandi` (paid, awaiting decision — **this is the
admin's action queue**), `tasdiqlandi` (approved), `radEtildi`
(rejected), `muddatiTugadi` (expired). Omit the query param to list all.

```json
{
  "premiumRequests": [
    {
      "id": "...", "uid": "...", "fullName": "...", "phone": "...",
      "amount": 9900, "months": 1, "status": "tolandi",
      "createdAt": "...", "expiresAt": "...", "paidAt": "..."
    }
  ]
}
```

### `POST /api/premium-requests/:id/approve`

Grants premium on `users/{uid}` (extends `premiumUntil` if still active,
else starts from now; `subscriptionPeriod * months`, matching
`PremiumRepository.grantPremium`) and sets the request's `status` to
`tasdiqlandi`, `decidedAt`, `decidedBy` (= calling admin's uid).

Response: `{ "premiumRequest": {...updated doc} }`. `404` if the
request id doesn't exist.

**Note**: unlike the Flutter app, this endpoint does **not** send a
push notification to the user on approval (`NotificationRepository` is
Dart/Firebase-Admin-SDK-based and out of scope for this Worker). Add
that separately if the dashboard needs it.

### `POST /api/premium-requests/:id/reject`

Body (optional): `{ "reason": "..." }`. Sets `status` to `radEtildi`,
`decidedAt`, `decidedBy`, and `rejectReason` if provided.

Response: `{ "premiumRequest": {...updated doc} }`. `404` if missing.
Same notification caveat as above.

### `GET /api/banners`

Lists all `promoBanners` docs, unfiltered.

```json
{ "banners": [ { "id": "...", "imageUrl": "...", "title": "...", "description": "...", "linkUrl": "...", "order": 0, "attribution": "...", "createdAt": "..." } ] }
```

### `POST /api/banners`

Body:

```json
{
  "imageUrl": "https://...",   // required — already-hosted URL; this Worker does not handle file upload
  "title": "...",              // required
  "description": "...",        // required
  "order": 0,                  // optional, defaults to 0
  "linkUrl": "https://...",    // optional
  "attribution": "..."         // optional — e.g. CC BY-SA credit line
}
```

`201 { "banner": {...created doc with id} }`. `400` if `imageUrl`,
`title`, or `description` are missing.

### `DELETE /api/banners/:id`

`200 { "ok": true }`.

### `GET /api/reports?status=<value>`

Lists `reports` docs, optionally filtered by exact `status`, newest
first. Matches `lib/features/moderation/data/report_repository.dart`,
whose `ReportStatus` enum values (`pending`, `reviewed`, `dismissed`)
already line up with the originally-assumed shape — but this endpoint
was written against the report_repository.dart that existed at the time
this Worker was built; **re-check that file before relying on this if
it may have changed since**.

```json
{
  "reports": [
    {
      "id": "...", "reporterUid": "...", "targetType": "chatMessage",
      "targetId": "...", "targetSnippet": "...", "mahallaId": "...",
      "reason": "spam", "details": "...", "status": "pending",
      "createdAt": "...", "reviewedBy": null, "reviewedAt": null
    }
  ]
}
```

`targetType` ∈ `chatMessage | announcement | serviceAd | user`.
`reason` ∈ `spam | haqoratOmuhandaslik | aldash | nomunosib | boshqa`.

### `POST /api/reports/:id/resolve`

Body: `{ "outcome": "reviewed" | "dismissed" }` (required). Sets
`status` to `outcome`, `reviewedAt` to now, `reviewedBy` to the calling
admin's uid.

Response: `{ "report": {...updated doc} }`. `400` if `outcome` is
missing/invalid, `404` if the report doesn't exist.

## CORS

All routes (including error responses) send CORS headers allowing
`env.ALLOWED_ORIGIN` (currently `*`). `OPTIONS` preflight is handled.

## Stats aggregation (cron)

Runs every 30 minutes (`[triggers] crons` in `wrangler.toml`). Computes,
via Firestore aggregation (`count()`) queries:

- `total_mahallas` — count of `mahallas` docs.
- `total_users` — count of `users` docs.
- `total_active_requests` — **collection group** count query over
  `requests` (path: `mahallas/{id}/requests/{reqId}`, per
  `lib/features/requests/data/requests_repository.dart`) where
  `status IN ['yangi', 'jarayonda']` (i.e. not `yakunlandi`).
- `total_pending_premium` — count of `premiumRequests` where
  `status == 'tolandi'`.

Upserts these into Supabase `admin_stats` (id=1, single row, via
`Prefer: resolution=merge-duplicates` on-conflict upsert). A cron
failure is logged and swallowed (not thrown) — `/api/stats` degrades to
serving the last-known row, or zeros if none exists yet.

## Assumptions / TODOs

1. **`reports` collection shape** — matched against the real
   `lib/features/moderation/data/report_repository.dart` as it existed
   when this Worker was written. If the moderation feature's schema
   changes later, update the `GET /api/reports` and
   `POST /api/reports/:id/resolve` handlers in `index.js` to match.
2. **CORS origin** — currently wildcard `*`. Tighten `ALLOWED_ORIGIN` in
   `wrangler.toml` `[vars]` once the admin frontend's real domain is
   known.
3. **Push notifications on premium approve/reject** — the Flutter
   repository sends a notification via `NotificationRepository` on
   approve/reject; this Worker does not replicate that (would require
   either calling a Cloud Function or duplicating FCM-send logic here).
   Flagged as a gap, not implemented.
4. **Service account IAM role** — the OAuth2 access token this Worker
   mints only has the `datastore` scope; it needs the service account to
   actually have Firestore read/write IAM permissions in the GCP
   project (e.g. "Cloud Datastore User"). Verify this when creating/
   choosing the service account.
5. **Firestore composite indexes** — `GET /api/premium-requests?status=...`
   (equality on `status` + `orderBy(createdAt desc)`) needs a composite
   index on `premiumRequests`; this already exists because the Flutter
   app's `watchPendingRequests()` runs the identical query. `GET
   /api/reports?status=...` uses the same shape on `reports`, but as far
   as this agent could tell nothing in the current Flutter app runs that
   query yet (`report_repository.dart` only writes reports, it doesn't
   query them) — so a `reports` composite index (`status` ASC,
   `createdAt` DESC) may need to be created in the Firebase console the
   first time this endpoint is called with a `status` filter (Firestore
   returns a 400 with a direct "create it here" link the first time this
   happens — check `firestore.indexes.json` and deploy it there too if
   you want it version-controlled).
6. **Firestore `IN` query limits** — the collection-group "active
   requests" count uses an `IN` filter with 2 values, well under
   Firestore's 30-value cap, so no pagination/batching concerns there.
7. Not tested against real Firebase/Supabase credentials (none were
   available). The RS256 sign/verify and X.509-cert public-key
   extraction logic in `lib/jwt.js` *was* unit-tested locally against a
   real OpenSSL-generated RSA keypair + self-signed certificate (signed
   a JWT, verified it against the cert's extracted public key, and
   confirmed a tampered token fails verification) — but the full
   request flow (Firebase token verification against Google's actual
   certs, the live OAuth2 token exchange, real Firestore/Supabase calls)
   has not been exercised end-to-end. `wrangler deploy --dry-run`
   confirms the Worker bundles and the `wrangler.toml` config is valid.
