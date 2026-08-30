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
  Firestore's tagged `{stringValue: ...}` REST value format. Also
  exports `FieldDelete`, a sentinel passed as a `patchDoc` field value
  to delete that field entirely (mirrors the Flutter app's
  `FieldValue.delete()`) — used by `POST /api/users/:uid/premium/revoke`.
- `lib/supabase.js` — reads/upserts the single `admin_stats` row, and
  inserts/reads the append-only `admin_stats_history` log, via Supabase
  PostgREST.
- `lib/auth.js` — `requireSuperAdmin()`: verifies the bearer token, then
  checks `users/{uid}.role == 'superAdmin'` in Firestore.
- `lib/http.js` — CORS headers, JSON responses, `HttpError`.
- `lib/audit.js` — `logAudit()`: writes a doc to the top-level
  `adminAuditLog` Firestore collection after every mutating admin
  action. Failures are caught and logged, never thrown — an audit-log
  write failure must never break the actual admin action.
- `supabase-schema.sql` — the `admin_stats` and `admin_stats_history`
  table definitions. Run once in the Supabase SQL editor (re-run if
  you're adding `admin_stats_history` to an already-provisioned
  project — `create table if not exists` makes it safe to re-run the
  whole file).

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
for project `dsbnguwyokxcxfcbeaym` (safe to re-run — every statement is
`create table if not exists`).

**Firestore rules**: the repo-root `firestore.rules` has a new
`adminAuditLog` block (`allow read: if isSuperAdmin(); allow write: if
false;`) — deploy it (`firebase deploy --only firestore:rules` from the
repo root, or via the Firebase Console) so `GET /api/audit-log` is
actually readable and so no mobile client can ever write to that
collection. The Worker itself doesn't need this deployed to *write*
audit-log entries (its service-account credentials bypass rules
entirely, same as every other Firestore write it makes) — it's only
needed for the `isSuperAdmin()` read check to apply to any other
caller.

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

### `GET /api/stats/history?days=<n>`

Trend-chart data from the append-only `admin_stats_history` table (one
row inserted per cron run, every 30 min — see "Stats aggregation (cron)"
below). `days` is optional, defaults to `30`, capped at `90`. Returns
rows with `recorded_at >= now() - days`, oldest first (natural x-axis
order for a chart).

```json
{
  "history": [
    {
      "totalMahallas": 12, "totalUsers": 340, "totalActiveRequests": 27,
      "totalPendingPremium": 3, "recordedAt": "2026-08-01T06:30:00.000Z"
    }
  ]
}
```

If the cron job hasn't run (enough times) yet, `history` may be an empty
array — this endpoint never synthesizes fallback zero rows the way
`GET /api/stats` does.

### `GET /api/mahallas`

Lists all documents in the `mahallas` collection, unfiltered.

```json
{ "mahallas": [ { "id": "...", ...allFieldsFromTheDoc }, ... ] }
```

### `GET /api/mahallas/:id/detail`

One mahalla's own doc fields plus counts scoped to just that mahalla —
built for a mahalla detail/drill-down screen. `404` if the mahalla
doesn't exist.

```json
{
  "mahalla": {
    "id": "...", "name": "...", "district": "...", "extra": "...",
    "latitude": 41.0, "longitude": 69.0, "boundary": [ { "lat": 41.0, "lng": 69.0 } ],
    "rais": { "id": "...", "firstName": "...", "lastName": "...", "phone": "...", "...": "...other user fields" },
    "raisCount": 1,
    "memberCount": 214,
    "requestsByStatus": { "yangi": 3, "jarayonda": 1, "yakunlandi": 40 },
    "counts": { "announcements": 12, "events": 4, "polls": 2, "serviceAds": 6, "services": 9 }
  }
}
```

Field-name notes (verified against the actual Flutter/Dart source, not
assumed):

- The `mahallas` doc itself has **no** rais/admin field —
  `lib/features/qr/data/mahalla_repository.dart`'s `MahallaInfo` only
  has `name`/`district`/`extra`/`latitude`/`longitude`/`boundary`. "Rais
  info" is resolved separately, by querying `users` for `mahallaId ==
  :id AND role == 'rais'`. `rais` is the first match (raw user doc,
  same shape as `GET /api/users`'s items), or `null` if no rais is
  currently assigned. `raisCount` is included in case more than one
  user somehow has `role: 'rais'` for this mahalla (normally exactly 0
  or 1).
- `memberCount` is **not** a count of `users where mahallaId == :id`.
  Per `lib/features/home/data/home_repository.dart`'s extensive comment
  on `watchMahallaMembers`, the app can't run that query client-side at
  all (Firestore "list" query rules can't be proven against a value
  read from a different doc) — membership is instead tracked via a
  `mahallas/{id}/members/{uid}` marker subcollection, one doc per
  member, kept in sync by `MahallaRepository.attachUserToMahalla`. This
  endpoint counts that marker subcollection, matching what the app
  itself treats as the source of truth. It also naturally excludes the
  superAdmin technical account (no marker doc is ever written for one —
  a superAdmin never goes through the QR-join flow).
- `requestsByStatus` counts `mahallas/{id}/requests` docs by `status`
  (`yangi`/`jarayonda`/`yakunlandi`), scoped to just this mahalla (not a
  collection-group query).
- `counts.*` are simple per-mahalla subcollection counts (`announcements`,
  `events`, `polls`, `serviceAds`, `services`), computed the same way
  `computeAndStoreStats` computes the global stats, via Firestore
  aggregation (`count()`) queries — just scoped to one mahalla's
  subcollections instead of a collection-group query across all of
  them.

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

### `PATCH /api/banners/:id`

Partial update. `promo_banner_repository.dart` has no `updateBanner`
method of its own (only `createBanner`/`deleteBanner`) — this endpoint
mirrors `createBanner`'s full field set (not just `imageUrl`/`linkUrl`/
`order`), since a real edit form needs to touch title/description too.

Body (all optional, at least one required):

```json
{
  "imageUrl": "https://...",
  "title": "...",
  "description": "...",
  "order": 0,
  "linkUrl": "https://...",
  "attribution": "..."
}
```

`200 { "banner": {...updated doc} }`. `400` if no updatable field is
provided, or if a provided `imageUrl`/`title`/`description` is an empty
string, or `order` isn't an integer. `404` if the banner doesn't exist.

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

### `GET /api/announcements?mahallaId=<id>`

Lists `mahallas/{mahallaId}/announcements` docs, newest first
(`createdAt` descending). Matches
`lib/features/announcements/data/announcement_repository.dart`'s
`Announcement.fromFirestore`.

If `mahallaId` is omitted, runs a Firestore **collection group** query
across every mahalla's `announcements` subcollection instead — each doc
in the response then carries a `mahallaId` field so the frontend knows
which mahalla it belongs to (needed for the delete route below, since
these are subcollection docs, not top-level). When `mahallaId` is
provided, the response docs also carry `mahallaId` (just the value you
passed) for a consistent shape either way.

```json
{
  "announcements": [
    {
      "id": "...", "mahallaId": "...", "title": "...", "body": "...",
      "category": "kommunal", "createdAt": "...", "imageUrl": "...",
      "authorUid": "...", "reactedUids": { "uid1": "👍" }
    }
  ]
}
```

`category` ∈ `kommunal | xavfsizlik | umumiy`. `body` may be Quill
Delta JSON (rich text) rather than plain text — see
`Announcement.plainTextPreview` in the Dart source if you need a plain
preview client-side.

### `POST /api/announcements`

Matches `AnnouncementRepository.createAnnouncement`. `authorUid` is
always set to the calling superAdmin's uid (the Dart model's
`authorUid` is required/non-nullable). `reactedUids` is never written
here — new announcements simply start with none.

Body:

```json
{
  "mahallaId": "...",           // required
  "title": "...",               // required
  "body": "...",                // required — plain text or Quill Delta JSON
  "category": "kommunal",       // required — "kommunal" | "xavfsizlik" | "umumiy"
  "imageUrl": "https://..."     // optional
}
```

`201 { "announcement": {...created doc, with mahallaId} }`. `400` if
`mahallaId`/`title`/`body` are missing or `category` is invalid.

**Note**: unlike `createAnnouncement`, this endpoint does not send a
push notification to the mahalla — same out-of-scope caveat as the
premium approve/reject and request-status endpoints.

### `PATCH /api/announcements/:mahallaId/:id`

Partial update of `title`/`body`/`category`/`imageUrl` (all optional,
at least one required). Deliberately never touches `reactedUids` —
that field is only ever mutated by the mobile app's reaction toggle
(`AnnouncementRepository.toggleReaction`), and since `patchDoc` only
sends an `updateMask` for the fields you provide, omitting
`reactedUids` from the body guarantees it's left untouched.

Body: same shape as `POST`, all fields optional.

`200 { "announcement": {...updated doc, with mahallaId} }`. `400` if no
updatable field is provided or a provided field is invalid, `404` if
the announcement doesn't exist.

### `DELETE /api/announcements/:mahallaId/:id`

`200 { "ok": true }`. Succeeds even if the doc doesn't already exist
(matches `deleteDoc`'s existing silent-404 behavior).

### `GET /api/events?mahallaId=<id>`

Lists `mahallas/{mahallaId}/events` docs, newest first (`dateTime`
descending — note this orders by the event's scheduled date/time, not
`createdAt`, matching `EventRepository.watchEvents`). Same
`mahallaId`-omitted collection-group behavior as `/api/announcements`.

```json
{
  "events": [
    {
      "id": "...", "mahallaId": "...", "title": "...", "dateTime": "...",
      "location": "...", "participantsCount": 0, "createdAt": "...",
      "authorUid": "..."
    }
  ]
}
```

### `POST /api/events`

Matches `EventRepository.createEvent`. `participantsCount` always
starts at `0` (it's incremented elsewhere by the app, not settable at
creation) and `authorUid` is set to the calling superAdmin's uid.

Body:

```json
{
  "mahallaId": "...",              // required
  "title": "...",                  // required
  "dateTime": "2026-09-15T18:00:00.000Z",  // required — ISO 8601 string
  "location": "..."                // required
}
```

`201 { "event": {...created doc, with mahallaId} }`. `400` if any
required field is missing or `dateTime` isn't a valid ISO 8601 string.
Same no-push-notification caveat as announcements.

### `PATCH /api/events/:mahallaId/:id`

Partial update of `title`/`dateTime`/`location` (all optional, at least
one required) — matches `EventRepository.updateEvent`, which also
never touches `participantsCount`.

`200 { "event": {...updated doc, with mahallaId} }`. `400`/`404` same
pattern as announcements' PATCH.

### `DELETE /api/events/:mahallaId/:id`

`200 { "ok": true }`.

### `GET /api/requests?mahallaId=<id>&status=<value>`

Lists `mahallas/{mahallaId}/requests` docs (the "murojaat" feature),
newest first. Both query params are optional and independent:
`mahallaId` scopes to one mahalla vs. a collection-group query across
all of them (same pattern as above); `status` filters by exact match.

```json
{
  "requests": [
    {
      "id": "...", "mahallaId": "...", "title": "...", "description": "...",
      "status": "yangi", "type": "maxfiy", "priority": "ortacha",
      "joinedCount": 0, "joinedUids": [], "createdAt": "...",
      "authorUid": "...", "imageUrls": [], "latitude": null,
      "longitude": null, "authorWasPremium": false
    }
  ]
}
```

- `status` ∈ `yangi | jarayonda | yakunlandi`.
- `type` ∈ `maxfiy` (private — only the author + rais see it) `| ommaviy`
  (public — visible to the whole mahalla).
- `priority` ∈ `past | ortacha | yuqori`.
- `description` may be Quill Delta JSON, same caveat as announcements'
  `body`.

Matches `lib/features/requests/data/requests_repository.dart`'s
`MahallaRequest.fromFirestore`.

### `POST /api/requests/:mahallaId/:id/status`

Body: `{ "status": "yangi" | "jarayonda" | "yakunlandi" }` (required).

Response: `{ "request": {...updated doc, with mahallaId} }`. `400` if
`status` is missing/invalid, `404` if the request doesn't exist.

**Note**: unlike `RequestsRepository.updateRequestStatus` in the
Flutter app, this endpoint does **not** send the author a push
notification — same out-of-scope caveat as the premium
approve/reject endpoints (`NotificationRepository` is
Dart/Firebase-Admin-SDK-based).

### `GET /api/polls?mahallaId=<id>`

Lists `mahallas/{mahallaId}/polls` docs, newest first. Same
`mahallaId`-omitted collection-group behavior as above. Each poll
includes both the **raw doc** (so nothing is lost/reshaped) and a
computed `results` object with vote counts, so the frontend doesn't
need to re-implement `Poll.voteCounts`/`Poll.totalVotes` from
`lib/features/polls/data/poll_repository.dart`.

```json
{
  "polls": [
    {
      "id": "...", "mahallaId": "...", "question": "...",
      "options": ["A", "B", "C"], "authorUid": "...", "createdAt": "...",
      "allowMultiple": false, "isAnonymous": false, "closesAt": null,
      "votes": { "uid1": [0], "uid2": [0, 2] },
      "results": { "voteCounts": [2, 0, 1], "totalVotes": 2 }
    }
  ]
}
```

`results.voteCounts[i]` is the number of voters who selected option `i`
(a voter with `allowMultiple` can count toward multiple options).
`results.totalVotes` is the number of voters with at least one
selection (matches `Poll.totalVotes`, i.e. it's *voters*, not
*selections*). `votes` is the raw `uid -> [optionIndex, ...]` map,
already normalized to the "new" list format even for legacy
single-int-per-uid docs — see `decodeValue`/the Dart-side
`Poll._parseVotes` comment; **this Worker's decode does NOT do that
legacy-int normalization**, so if any pre-v1.2 poll docs with a bare
integer vote value still exist, that voter's raw `votes` entry here
will be a plain number rather than `[number]`, and it's excluded from
`results` (only array values are counted). In practice this only
matters for very old, unmigrated poll docs.

### `POST /api/polls`

Matches `PollRepository.createPoll`. `votes` always starts as `{}` —
after creation, only the mobile app's `vote()` call ever writes into
it. `authorUid` is set to the calling superAdmin's uid.

Body:

```json
{
  "mahallaId": "...",           // required
  "question": "...",            // required
  "options": ["A", "B", "C"],   // required — at least 2 non-empty strings
  "allowMultiple": false,       // optional, defaults to false
  "isAnonymous": false,         // optional, defaults to false
  "closesAt": "2026-09-01T00:00:00.000Z"  // optional, ISO 8601 string or null/omitted for "never closes"
}
```

`201 { "poll": {...created doc, with mahallaId and results} }` (same
`results` shape as the `GET` endpoint, computed from the now-empty
`votes`). `400` if `mahallaId`/`question` are missing, `options` has
fewer than 2 non-empty strings, or `closesAt` is present but not a
valid ISO 8601 string. Same no-push-notification caveat as
announcements.

### `PATCH /api/polls/:mahallaId/:id`

Partial update of `question`/`options`/`allowMultiple`/`isAnonymous`/
`closesAt` (all optional, at least one required; `closesAt` can be set
to `null` to clear it). **Deliberately never touches `votes`** — that's
mutated only by the mobile app's voting flow.

**Note this differs from `PollRepository.updatePoll`**, which resets
`votes` to `{}` whenever it's called (to avoid stale option indexes
after an options edit) — this endpoint leaves that judgment call to the
frontend/caller instead: if you change `options` in a way that
invalidates existing vote indexes, decide separately whether to also
call something that clears `votes` (there's currently no dedicated
endpoint for that — `DELETE` + re-`POST` the poll is the only way via
this API today).

`200 { "poll": {...updated doc, with mahallaId and results} }`. `400`/
`404` same pattern as announcements' PATCH.

### `DELETE /api/polls/:mahallaId/:id`

`200 { "ok": true }`.

### `GET /api/service-ads?mahallaId=<id>`

Lists `mahallas/{mahallaId}/serviceAds` docs (paid classified ads),
newest first (`createdAt` descending — includes expired ads, unlike
the Flutter app's `watchActiveAds`; this mirrors
`ServiceAdRepository.watchAllAds`, the admin-facing stream). Same
`mahallaId`-omitted collection-group behavior as above.

```json
{
  "serviceAds": [
    {
      "id": "...", "mahallaId": "...", "title": "...", "description": "...",
      "phone": "...", "ownerName": "...", "activeUntil": "...",
      "createdAt": "..."
    }
  ]
}
```

### `POST /api/service-ads`

Matches `ServiceAdRepository.createAd`. **Important correction vs. an
earlier assumption**: the actual doc schema is just
`title`/`description`/`phone`/`ownerName`/`activeUntil`/`createdAt` —
there is **no** `category` or `weeklyPrice` field stored per-doc
(`weeklyPrice` is a static price constant in the Dart repository, not
per-ad data). Don't send those.

Body:

```json
{
  "mahallaId": "...",       // required
  "title": "...",           // required
  "description": "...",     // required
  "phone": "...",           // required
  "ownerName": "...",       // required
  "durationDays": 7         // optional, defaults to 7 (matches ServiceAdRepository.defaultDuration) — activeUntil = now + durationDays
}
```

`201 { "serviceAd": {...created doc, with mahallaId} }`. `400` if any
required field is missing.

### `PATCH /api/service-ads/:mahallaId/:id`

Partial update of `title`/`description`/`phone`/`ownerName` (all
optional). There is no dedicated `updateAd` in the Dart repository
(only `createAd`/`deleteAd`/`extendAd`), so this endpoint also accepts
an optional `durationDays` + `extendFromCurrent` pair to adjust
`activeUntil`, mirroring `ServiceAdRepository.extendAd`'s logic:

```json
{
  "title": "...",              // optional
  "description": "...",        // optional
  "phone": "...",              // optional
  "ownerName": "...",          // optional
  "durationDays": 7,           // optional — if present, recomputes activeUntil
  "extendFromCurrent": true    // optional, defaults to false — true: activeUntil = max(now, current activeUntil) + durationDays (matches extendAd); false/omitted: activeUntil = now + durationDays
}
```

At least one field must be provided. `200 { "serviceAd": {...updated
doc, with mahallaId} }`. `400` if no updatable field is provided or
`durationDays` isn't a number, `404` if the ad doesn't exist.

### `DELETE /api/service-ads/:mahallaId/:id`

`200 { "ok": true }`.

### `GET /api/services?mahallaId=<id>`

Lists `mahallas/{mahallaId}/services` docs (the "Xizmatlar" local
service-provider directory — admin-curated listings like
plumber/electrician that residents call directly — **distinct from**
the paid `serviceAds` classifieds above), newest first. Matches
`lib/features/services/data/service_repository.dart`'s `LocalService`.
Same `mahallaId`-omitted collection-group behavior as
announcements/events/polls/service-ads.

```json
{
  "services": [
    {
      "id": "...", "mahallaId": "...", "name": "...",
      "category": "santexnik", "phone": "...", "description": "...",
      "authorUid": "...", "createdAt": "..."
    }
  ]
}
```

`category` ∈ `santexnik | elektrik | duradgor | tozalash | qurilish |
boshqa`.

### `POST /api/services`

Matches `ServiceRepository.createService`. `authorUid` is set to the
calling superAdmin's uid.

Body:

```json
{
  "mahallaId": "...",       // required
  "name": "...",            // required
  "category": "santexnik",  // required — one of the values listed above
  "phone": "...",           // required
  "description": "..."      // required
}
```

`201 { "service": {...created doc, with mahallaId} }`. `400` if any
required field is missing or `category` is invalid.

### `PATCH /api/services/:mahallaId/:id`

Partial update of `name`/`category`/`phone`/`description` (all
optional, at least one required) — matches
`ServiceRepository.updateService`, which also never touches
`authorUid`/`createdAt`.

`200 { "service": {...updated doc, with mahallaId} }`. `400`/`404`
same pattern as the other subcollection PATCH endpoints.

### `DELETE /api/services/:mahallaId/:id`

`200 { "ok": true }`.

### `GET /api/users?search=<value>`

Searches the top-level `users` collection. **Limitation: exact-prefix
match only, case-sensitive, on a single field — not a full substring
search.** Firestore's REST API has no native substring/full-text query,
so this uses the standard Firestore "prefix range" trick
(`field >= search AND field < search + ''`, ordered by that same
field) rather than building something more elaborate (e.g. a separate
search index) that felt out of scope here.

Field choice: if `search` looks like it could be a phone number (starts
with a digit or `+`, and the rest is digits/spaces/dashes), it queries
the `phone` field; otherwise it queries `firstName`. There's no
combined "full name" field on the user doc
(`lib/features/home/data/home_repository.dart`'s `UserProfile` only has
separate `firstName`/`lastName`), so a search for someone's last name
alone won't match — search by first name or phone. The response's
`searchedField` tells you which field was used. Results are capped at
50.

```json
{
  "users": [
    {
      "id": "...", "firstName": "...", "lastName": "...", "phone": "...",
      "mahallaId": "...", "role": "citizen", "staffTitle": null,
      "verifiedBadge": false, "premiumUntil": null, "...": "...other UserProfile fields"
    }
  ],
  "searchedField": "phone"
}
```

`400` if `search` is missing/empty.

### `POST /api/users/:uid/role`

Body: `{ "role": "citizen" | "staff" | "rais" | "superAdmin" }`
(required). Sets the user doc's `role` field directly.

Response: `{ "user": {...updated doc} }`. `400` if `role` is
missing/invalid, `404` if the user doesn't exist.

**Security-relevant, deliberate design decision — `superAdmin` grant is
allowed here.** Per `firestore.rules` and the comment on `UserRole` in
`lib/features/home/data/home_repository.dart`, the mobile app's own
security rules **never** allow granting `superAdmin` — it's meant to be
set by hand via Firebase Console only. This Worker's service-account
credentials bypass Firestore Security Rules entirely (same as the
Admin SDK), so this endpoint *can* technically grant `superAdmin`
through the dashboard.

This was kept intentional rather than blocked: the rules restriction
exists to stop a compromised/malicious **mobile client** from
self-granting the role — it's a client-trust boundary, not a
statement that superAdmin grants should never happen through any
programmatic path. A superAdmin acting through this already
auth-gated (`requireSuperAdmin`) admin panel, promoting another
trusted person to superAdmin, is a legitimate, intentional admin
action — arguably the whole point of having this endpoint instead of
requiring a trip to Firebase Console. **Reconsider this if it turns out
to be too permissive** — e.g. by carving `superAdmin` out into a
separate, more locked-down endpoint, or requiring some extra
confirmation step in the frontend before this call is made.

### `POST /api/users/:uid/premium/grant`

Direct premium grant, separate from the `premiumRequests` approve/
reject flow above — for use from a user-search/management UI (e.g.
comping a user premium without them filing a payment request). Mirrors
`PremiumRepository.grantPremium` exactly: if `premiumUntil` is still in
the future, extends it; otherwise starts from now. Adds
`subscriptionPeriod` (30 days) `* months`.

Body: `{ "months": 1 }` (optional, defaults to `1`, must be a positive
integer if provided).

`200 { "user": {...updated doc} }`. `400` if `months` is present but
not a positive integer, `404` if the user doesn't exist.

### `POST /api/users/:uid/premium/revoke`

Mirrors `PremiumRepository.revokePremium` exactly: **deletes** the
`premiumUntil` field from the user doc entirely (Firestore
field-delete via `updateMask` + omitting the field from the write —
see `FieldDelete` in `lib/firestore.js`), not merely setting it to
`null` or a past date — matching the Dart `FieldValue.delete()` call.

No body. `200 { "user": {...updated doc, without premiumUntil} }`.
`404` if the user doesn't exist.

### `GET /api/audit-log?limit=<n>`

Lists recent `adminAuditLog` docs, newest first (`timestamp` descending).
`limit` is optional, defaults to `50`, capped at `200`.

This collection is written **only** by this Worker (via `lib/audit.js`'s
`logAudit()`), after every mutating (POST/PATCH/DELETE) admin action —
see the full list of `action` values below. `firestore.rules` has a
matching `adminAuditLog` block with `allow write: if false` (the Worker's
service-account credentials bypass rules entirely, same as everywhere
else in this API — that `false` exists purely to guarantee no mobile
client can ever forge an entry) and `allow read: if isSuperAdmin()`.

```json
{
  "auditLog": [
    {
      "id": "...", "actorUid": "...", "action": "banner.delete",
      "details": { "bannerId": "..." }, "timestamp": "2026-08-30T10:00:00.000Z"
    }
  ]
}
```

`action` values currently written, one per mutating endpoint (`details`
always includes at least the target id, plus `mahallaId` where
applicable):

| Endpoint | `action` |
| --- | --- |
| `POST /api/premium-requests/:id/approve` | `premium.approve` |
| `POST /api/premium-requests/:id/reject` | `premium.reject` |
| `POST /api/banners` | `banner.create` |
| `PATCH /api/banners/:id` | `banner.update` |
| `DELETE /api/banners/:id` | `banner.delete` |
| `POST /api/reports/:id/resolve` | `report.resolve` |
| `POST /api/announcements` | `announcement.create` |
| `PATCH /api/announcements/:mahallaId/:id` | `announcement.update` |
| `DELETE /api/announcements/:mahallaId/:id` | `announcement.delete` |
| `POST /api/events` | `event.create` |
| `PATCH /api/events/:mahallaId/:id` | `event.update` |
| `DELETE /api/events/:mahallaId/:id` | `event.delete` |
| `POST /api/requests/:mahallaId/:id/status` | `request.status` |
| `POST /api/polls` | `poll.create` |
| `PATCH /api/polls/:mahallaId/:id` | `poll.update` |
| `DELETE /api/polls/:mahallaId/:id` | `poll.delete` |
| `POST /api/service-ads` | `serviceAd.create` |
| `PATCH /api/service-ads/:mahallaId/:id` | `serviceAd.update` |
| `DELETE /api/service-ads/:mahallaId/:id` | `serviceAd.delete` |
| `POST /api/services` | `service.create` |
| `PATCH /api/services/:mahallaId/:id` | `service.update` |
| `DELETE /api/services/:mahallaId/:id` | `service.delete` |
| `POST /api/users/:uid/role` | `user.role.update` |
| `POST /api/users/:uid/premium/grant` | `premium.grant` |
| `POST /api/users/:uid/premium/revoke` | `premium.revoke` |

**Note**: a failed audit-log write never fails the underlying admin
action — it's logged server-side (`console.error`) and swallowed. So the
absence of an expected audit-log entry doesn't necessarily mean the
action itself failed; check the resource's own state.

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
`Prefer: resolution=merge-duplicates` on-conflict upsert), then
**inserts** the same four numbers as a new row into the append-only
`admin_stats_history` table (used by `GET /api/stats/history` for trend
charts — unlike `admin_stats`, this table is never overwritten in
place, so every 30-min run adds one more data point). The history
insert is wrapped in its own try/catch, separate from the `admin_stats`
upsert — a failure there is logged and swallowed without affecting the
`admin_stats` cache write that already succeeded. A failure in the
outer aggregation itself (the Firestore queries) is likewise logged and
swallowed (not thrown) — `/api/stats` degrades to serving the
last-known row, or zeros if none exists yet.

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

   The same applies, more broadly, to the new `mahallaId`-omitted
   (collection-group) modes of `GET /api/announcements`, `/api/events`,
   `/api/requests`, `/api/polls`, and `/api/service-ads`: each is a
   collection-group query with an `orderBy` (plus, for `/api/requests`,
   an optional equality filter on `status` too), which needs a
   **collection-group** composite index (not the regular per-collection
   index the Flutter app's own per-mahalla queries already have) the
   first time it's called without `mahallaId`. Firestore's 400 response
   includes a direct "create it here" link the first time each shape is
   hit — same as above, add to `firestore.indexes.json` if you want
   these version-controlled. The `mahallaId`-scoped mode of each of
   these endpoints reuses the exact same query shape the Flutter app
   already runs per-mahalla (e.g. `AnnouncementRepository.
   watchAnnouncements`), so those should already have indexes (simple
   single-field `orderBy` doesn't need a composite index at all, except
   `/api/requests?status=...&mahallaId=...` which needs the same
   `status` + `createdAt` composite as `/api/premium-requests`).

   `GET /api/users?search=...`'s prefix-range query (`>=`/`<` on
   `phone` or `firstName`, ordered by the same field) also needs a
   single-field index on whichever field is queried — Firestore
   auto-creates single-field indexes by default, so this should work
   out of the box unless single-field indexing has been explicitly
   disabled for `phone`/`firstName` in `firestore.indexes.json`.
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
8. **`GET /api/mahallas/:id/detail`'s rais lookup needs a composite
   index** — it queries `users` for `mahallaId == X AND role == 'rais'`,
   an equality-equality composite filter with no `orderBy`. Firestore
   auto-creates single-field indexes but not composite ones; the first
   call will 400 with a direct "create it here" link if this exact
   composite doesn't already exist (it may already, if some other
   query in the app uses the same `mahallaId` + `role` shape — not
   confirmed either way). Add to `firestore.indexes.json` if you want
   it version-controlled, same as the other composite-index notes above.
9. **`admin_stats_history` unbounded growth** — the table is
   append-only and nothing here prunes it (one row every 30 min is
   ~17,520 rows/year — small, but worth a retention policy or a
   scheduled cleanup query in Supabase eventually if this runs for
   years unattended).
