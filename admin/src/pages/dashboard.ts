import { api } from '../lib/api';
import { renderLoading, renderError, formatDate, escapeHtml } from '../lib/ui';

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
    const stats = await api.getStats();
    body.innerHTML = `
      <div class="stat-grid">
        <div class="stat-card">
          <div class="stat-label">Mahallalar soni</div>
          <div class="stat-value">${escapeHtml(stats.total_mahallas)}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">Foydalanuvchilar soni</div>
          <div class="stat-value">${escapeHtml(stats.total_users)}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">Faol so'rovlar</div>
          <div class="stat-value">${escapeHtml(stats.total_active_requests)}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">Kutilayotgan premium</div>
          <div class="stat-value">${escapeHtml(stats.total_pending_premium)}</div>
        </div>
      </div>
      <p class="updated-note">
        Ma'lumotlar har ~30 daqiqada yangilanadi. Oxirgi yangilanish: ${formatDate(stats.updated_at)}
      </p>
    `;
  } catch (err) {
    renderError(body, err);
  }
}
