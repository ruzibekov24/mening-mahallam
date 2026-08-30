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
