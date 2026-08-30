// Thin wrapper around Supabase's PostgREST API for the single-row
// `admin_stats` cache table and the append-only `admin_stats_history`
// log table. See admin-worker/supabase-schema.sql for both table
// definitions.

function restUrl(env, path) {
  return `https://${env.SUPABASE_PROJECT_REF}.supabase.co/rest/v1/${path}`;
}

function authHeaders(env) {
  return {
    apikey: env.SUPABASE_SERVICE_ROLE_KEY,
    authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
    'content-type': 'application/json',
  };
}

/**
 * Reads the single `admin_stats` row. Returns null if the table is empty
 * (e.g. the cron job hasn't run yet) or the row doesn't exist — callers
 * should treat that as "no stats yet" rather than an error.
 */
export async function getStats(env) {
  const res = await fetch(`${restUrl(env, 'admin_stats')}?id=eq.1&select=*`, {
    headers: authHeaders(env),
  });
  if (!res.ok) throw new Error(`Supabase getStats failed: ${res.status}`);
  const rows = await res.json();
  return rows[0] || null;
}

/**
 * Upserts the single stats row (id=1). `Prefer: resolution=merge-duplicates`
 * makes Postgres perform an `ON CONFLICT (id) DO UPDATE`-style upsert via
 * PostgREST without us needing to hand-write the SQL.
 */
export async function upsertStats(env, stats) {
  const res = await fetch(`${restUrl(env, 'admin_stats')}?on_conflict=id`, {
    method: 'POST',
    headers: {
      ...authHeaders(env),
      prefer: 'resolution=merge-duplicates',
    },
    body: JSON.stringify({ id: 1, ...stats, updated_at: new Date().toISOString() }),
  });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`Supabase upsertStats failed: ${res.status} ${body}`);
  }
}

/**
 * Inserts one row into the append-only `admin_stats_history` table —
 * called once per cron run, right after `upsertStats`, with the exact
 * same computed numbers. Unlike `upsertStats` this never overwrites a
 * prior row; each call adds a new one so `GET /api/stats/history` can
 * serve a trend over time.
 */
export async function insertStatsHistory(env, stats) {
  const res = await fetch(restUrl(env, 'admin_stats_history'), {
    method: 'POST',
    headers: authHeaders(env),
    body: JSON.stringify({ ...stats, recorded_at: new Date().toISOString() }),
  });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`Supabase insertStatsHistory failed: ${res.status} ${body}`);
  }
}

/**
 * Reads `admin_stats_history` rows recorded at or after `sinceIso`,
 * ordered oldest-first (natural order for a trend chart's x-axis).
 */
export async function getStatsHistory(env, sinceIso) {
  const url =
    `${restUrl(env, 'admin_stats_history')}?recorded_at=gte.${encodeURIComponent(sinceIso)}` +
    `&order=recorded_at.asc&select=*`;
  const res = await fetch(url, { headers: authHeaders(env) });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`Supabase getStatsHistory failed: ${res.status} ${body}`);
  }
  return res.json();
}
