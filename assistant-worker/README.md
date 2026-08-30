# mahallam-assistant-api

Backend API for the "Mening Mahallam" AI chat assistant. Cloudflare
Worker, no build step, no npm dependencies — same style as
`admin-worker`: pure Workers runtime APIs (`fetch`, Web Crypto
`SubtleCrypto`) for Firebase ID token verification, plus a `fetch` call
to Google's Gemini API.

**Why this exists as a separate Worker, not a Gemini call from the
Flutter app directly**: a Gemini API key must never be embedded in the
mobile app — it would be trivially extractable from the APK, exposing
the key and risking abuse of the free quota by anyone who decompiles the
app. The key lives only as a Cloudflare Worker secret and is only ever
used server-side.

## Files

- `index.js` — routing + the `POST /chat` handler.
- `lib/jwt.js` — copied verbatim from `admin-worker/lib/jwt.js` (RS256
  sign/verify + PEM/DER helpers; only `verify` is actually used here).
- `lib/firebaseAuth.js` — copied verbatim from `admin-worker`: verifies
  Firebase ID tokens against Google's public certs (cached in a
  module-level variable per the certs' `Cache-Control: max-age`).
- `lib/auth.js` — **the one real difference from `admin-worker`'s
  `lib/auth.js`**: `requireAuthedUser()` only verifies the bearer token
  and returns the caller's uid — it does *not* look up a Firestore
  `role`. Any signed-in app user can use the AI assistant.
- `lib/rateLimit.js` — `enforceRateLimit()`: per-uid daily message quota,
  backed by Workers KV (see "Rate limiting" below).
- `lib/gemini.js` — `generateReply()`: builds Gemini's `contents` array
  from `{message, history}`, adds a locale-aware system instruction, and
  calls `POST .../models/{model}:generateContent`.
- `lib/http.js` — copied verbatim from `admin-worker`: CORS headers,
  JSON responses, `HttpError`.

## Setup (for you to run — not done by this agent)

**Secret** (`wrangler secret put GEMINI_API_KEY`, run from
`assistant-worker/`):

- `GEMINI_API_KEY` — get one free at https://aistudio.google.com/apikey.
  This agent did **not** set this secret, did **not** run
  `wrangler deploy`, and did **not** create the KV namespace below —
  all three are left for you.

**KV namespace** (for rate limiting):

```
wrangler kv namespace create RATE_LIMIT_KV
```

Copy the returned `id` into `wrangler.toml`'s `[[kv_namespaces]]` block
(currently a placeholder: `REPLACE_WITH_KV_NAMESPACE_ID`).

**Non-secret vars** — already set in `wrangler.toml` `[vars]`:

- `FIREBASE_PROJECT_ID = "mahallam-d4a93"` (also hardcoded as a constant
  inside `lib/firebaseAuth.js`, same as `admin-worker` — see the comment
  there if this ever needs to become env-driven instead).
- `ALLOWED_ORIGIN = "*"` — this Worker is called by the Flutter mobile
  app, not a browser, so strict CORS isn't load-bearing here, but kept
  configurable for consistency / in case a web client is added later.
- `GEMINI_MODEL = "gemini-2.0-flash"` — current Gemini free-tier model.
  Change here (no code change needed) if Google renames/deprecates it.
- `RATE_LIMIT_PER_DAY = "20"` — see "Rate limiting" below.

Then, once the secret and KV namespace both exist:

```
wrangler deploy
```
from `assistant-worker/`.

## Auth

`POST /chat` requires:

```
Authorization: Bearer <firebase-id-token>
```

Verified the same way as `admin-worker` (signature, `exp`, `iss`, `aud`)
— but **no role check**. Any authenticated "Mening Mahallam" user can
call this endpoint.

- `401` — missing/invalid/expired token.
- `400` — malformed request body.
- `429` — rate limit hit (see below), or Gemini itself is rate-limiting
  this Worker's API key.
- `502` — Gemini API unreachable, returned an error, or returned no
  usable text (e.g. blocked by safety filters).
- `500` — unexpected error, or `GEMINI_API_KEY` isn't set yet.

## API contract

### `GET /health`

No auth required. `200 {"ok": true}`.

### `POST /chat`

Request body:

```json
{
  "message": "Salom, menga qanday yordam bera olasiz?",
  "history": [
    { "role": "user", "text": "..." },
    { "role": "model", "text": "..." }
  ],
  "locale": "uz"
}
```

- `message` — required, non-empty string. The user's new message.
- `history` — optional array of `{role: "user"|"model", text: string}`,
  the recent conversation turns for context. Only the **last 10** turns
  are actually sent to Gemini (`MAX_HISTORY_TURNS` in `lib/gemini.js`) —
  older turns are silently dropped server-side to bound token usage; the
  client is free to keep a longer local history and just always send the
  tail of it.
- `locale` — optional, one of `"uz" | "ru" | "en"`. Controls both the
  language Gemini is instructed to answer in and the system-instruction
  text. Defaults to `"uz"` if omitted or any other value.

Response: `200 { "reply": "..." }`.

`400` if `message` is missing/empty, or `history`/`locale` are present
but the wrong type.

## Rate limiting

**Why this matters**: Gemini's free tier has a shared daily/per-minute
quota across the whole API key. Without a per-user limit, one user (or a
script hitting this endpoint directly, bypassing the app) could burn
through the entire app's free quota alone, breaking the assistant for
everyone else for the rest of the day.

**Mechanism**: Workers KV, not a Durable Object. `landing-worker` uses a
DO for its download counter because many different users' downloads all
increment the exact same shared counter object, where a naive
read-modify-write race would under-count. Here, every rate-limit key is
scoped to one `{uid, date}` pair — a single signed-in user isn't
expected to fire truly concurrent chat requests from the same
device/session, so the (small, theoretical) race window of two
simultaneous requests both reading the same pre-increment count is an
acceptable trade-off for the much simpler KV approach (no Durable Object
class, no migration, no extra binding wiring).

- Key: `ratelimit:{uid}:{YYYY-MM-DD}` (UTC date).
- Limit: **20 messages per user per day** (`RATE_LIMIT_PER_DAY` in
  `wrangler.toml` — change the var to retune, no code change needed).
- Storage: the counter is written with `expirationTtl: 172800` (2 days)
  so old keys clean themselves up automatically — no cron job needed to
  prune them.
- On limit hit: `429` with body
  `{ "error": "Kunlik AI yordamchi xabarlar limiti (20) tugadi. Ertaga qayta urinib ko'ring." }`.

**Known limitation**: the UTC calendar day, not the user's local day, is
what resets the counter — for Uzbekistan (UTC+5) this means the reset
happens at 05:00 local time, not midnight local time. Not corrected for
here since it wasn't specified as a requirement; adjust `todayKey()` in
`lib/rateLimit.js` (e.g. shift by a fixed UTC+5 offset) if a
midnight-local-time reset actually matters.

## CORS

All routes (including error responses) send CORS headers allowing
`env.ALLOWED_ORIGIN` (currently `*`). `OPTIONS` preflight is handled.
Not load-bearing for the mobile app (native HTTP calls aren't subject to
CORS), but kept for parity with `admin-worker` and in case a web client
calls this Worker later.

## Deploy / verification

- `node --check index.js` and `node --check lib/*.js` — all pass (pure
  syntax check, no Workers-runtime-only globals like `crypto.subtle` are
  exercised at parse time).
- `npx wrangler deploy --dry-run` — bundles successfully; see the
  agent's final report for the exact output. This does **not** require
  live credentials, but it also does not validate the KV namespace `id`
  placeholder in `wrangler.toml` — replace that before a real deploy (a
  real `wrangler deploy` would fail with an invalid/placeholder KV
  namespace id).

## Assumptions / TODOs

1. **Gemini model name** — `gemini-2.0-flash` was picked as a safe,
   current (as of this agent's knowledge) free-tier default. If Google
   has since shipped a newer default free-tier flash model, just update
   `GEMINI_MODEL` in `wrangler.toml` — no code change needed.
2. **UTC vs. local-day rate-limit reset** — see "Known limitation" above.
3. **KV eventual consistency** — Workers KV writes can take up to ~60s
   to propagate globally. In the rare case a user's requests land on
   different Cloudflare colos in quick succession, the rate limit could
   under-count by a request or two around that window. Not a concern at
   the scale of "20 messages/user/day", but worth knowing if the limit
   is ever tightened significantly.
4. **No conversation persistence** — this Worker is stateless per
   request; it has no memory of a conversation beyond what the client
   resends as `history` each time. This matches the Flutter side's
   design (in-memory-only chat screen, no Firestore chat log) — see
   `lib/features/assistant/` in the mobile app.
5. **`FIREBASE_PROJECT_ID` duplicated** — set both in `wrangler.toml`
   `[vars]` (currently unused by any handler, kept for
   documentation/consistency with `admin-worker`) and hardcoded as a
   constant inside `lib/firebaseAuth.js` (the one actually used for
   token audience-checking) — same duplication that already exists in
   `admin-worker`, not introduced fresh here.
