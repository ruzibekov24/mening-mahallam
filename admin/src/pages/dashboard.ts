import { api, type Stats, type StatsHistoryEntry } from '../lib/api';
import { renderLoading, renderError, formatDate, escapeHtml } from '../lib/ui';
import { renderSparkline } from '../lib/sparkline';

type StatKey = 'total_mahallas' | 'total_users' | 'total_active_requests' | 'total_pending_premium';

// `/api/stats` uses snake_case, `/api/stats/history` uses camelCase —
// this maps each dashboard card's stat key to its history-entry field.
const HISTORY_KEY: Record<StatKey, keyof StatsHistoryEntry> = {
  total_mahallas: 'totalMahallas',
  total_users: 'totalUsers',
  total_active_requests: 'totalActiveRequests',
  total_pending_premium: 'totalPendingPremium',
};

const STAT_CARDS: { key: StatKey; label: string }[] = [
  { key: 'total_mahallas', label: 'Mahallalar soni' },
  { key: 'total_users', label: 'Foydalanuvchilar soni' },
  { key: 'total_active_requests', label: "Faol so'rovlar" },
  { key: 'total_pending_premium', label: 'Kutilayotgan premium' },
];

export async function renderDashboard(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="page-header">
      <h1>Bosh sahifa</h1>
      <p>Umumiy statistika</p>
    </div>
    <div id="dashboard-body"></div>
  `;
  const body = container.querySelector<HTMLElement>('#dashboard-body')!;
  renderLoading(body);

  try {
    const [stats, history] = await Promise.all([
      api.getStats(),
      api.getStatsHistory(30).catch(() => [] as StatsHistoryEntry[]),
    ]);
    body.innerHTML = `
      <div class="stat-grid">
        ${STAT_CARDS.map((card) => renderStatCard(card.key, card.label, stats, history)).join('')}
      </div>
      <p class="updated-note">
        Ma'lumotlar har ~30 daqiqada yangilanadi. Oxirgi yangilanish: ${formatDate(stats.updated_at)}
      </p>
    `;
  } catch (err) {
    renderError(body, err);
  }
}

function renderStatCard(
  key: StatKey,
  label: string,
  stats: Stats,
  history: StatsHistoryEntry[]
): string {
  const values = history.map((h) => Number(h[HISTORY_KEY[key]]) || 0);
  const svg = renderSparkline(values);
  const trend = svg
    ? `<div class="sparkline-wrap">${svg}</div>`
    : `<div class="sparkline-wrap sparkline-empty">Tarix hali yo'q</div>`;
  return `
    <div class="stat-card">
      <div class="stat-label">${escapeHtml(label)}</div>
      <div class="stat-value">${escapeHtml((stats as unknown as Record<StatKey, number>)[key])}</div>
      ${trend}
    </div>
  `;
}
