// Simple per-user daily rate limit for POST /chat, backed by Workers KV.
//
// Why KV over a Durable Object: landing-worker's download counter uses a
// DO because concurrent bumps from *different* users all hit the exact
// same single counter object, where a naive read-modify-write race would
// under-count. Here every counter key is scoped to one `{uid}:{date}`
// pair — a single user can only plausibly send one chat message at a
// time from one device, so the tiny window for a lost increment (two
// requests racing on the same key) is an acceptable trade-off for not
// having to write/deploy a Durable Object class just for this. KV's
// built-in `expirationTtl` also gives us "reset at midnight-ish" for
// free, without a cron job to clear old counters.

import { HttpError } from './http.js';

/** YYYY-MM-DD in UTC — good enough for a daily quota; doesn't need to
 * match the user's local calendar day precisely. */
function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

/**
 * Throws `HttpError(429, ...)` if `uid` has already hit
 * `env.RATE_LIMIT_PER_DAY` messages today; otherwise increments the
 * counter and lets the caller proceed.
 */
export async function enforceRateLimit(env, uid) {
  const limit = parseInt(env.RATE_LIMIT_PER_DAY, 10) || 20;
  const key = `ratelimit:${uid}:${todayKey()}`;

  const raw = await env.RATE_LIMIT_KV.get(key);
  const count = raw ? parseInt(raw, 10) || 0 : 0;

  if (count >= limit) {
    throw new HttpError(
      429,
      `Kunlik AI yordamchi xabarlar limiti (${limit}) tugadi. Ertaga qayta urinib ko'ring.`,
    );
  }

  // TTL of 2 days: comfortably outlives "today" in any timezone relative
  // to the UTC date used as the key, so the counter is guaranteed to
  // still be around for the whole day it's counting, then cleans itself
  // up — no cron job needed to prune old keys.
  await env.RATE_LIMIT_KV.put(key, String(count + 1), { expirationTtl: 2 * 24 * 60 * 60 });
}
