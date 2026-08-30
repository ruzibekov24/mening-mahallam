// Thin wrapper around Supabase's PostgREST API for the single-row
// `admin_stats` cache table. See admin-worker/supabase-schema.sql for the
// table definition.

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
