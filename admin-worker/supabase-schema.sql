-- admin_stats: single-row cache of dashboard aggregate counts, written by
-- the admin-worker Cron Trigger (scheduled() in index.js, every 30 min)
-- and read by GET /api/stats.
--
-- Run this once in the Supabase SQL editor for project dsbnguwyokxcxfcbeaym.

create table if not exists admin_stats (
  id smallint primary key default 1,
  total_mahallas int,
  total_users int,
  total_active_requests int,
  total_pending_premium int,
  updated_at timestamptz,
  constraint admin_stats_singleton check (id = 1)
);

-- admin_stats_history: append-only log of the same four aggregate counts,
-- one row per Cron Trigger run (every 30 min — see scheduled() in
-- index.js), used to render trend charts (GET /api/stats/history) over
-- time. Unlike `admin_stats` above (a single-row cache, always
-- overwritten in place), every cron run INSERTs a new row here instead
-- of upserting, so the full history is preserved for as long as the
-- table isn't pruned.
create table if not exists admin_stats_history (
  id bigserial primary key,
  total_mahallas int,
  total_users int,
  total_active_requests int,
  total_pending_premium int,
  recorded_at timestamptz not null default now()
);
