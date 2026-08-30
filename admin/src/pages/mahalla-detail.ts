import { api, type MahallaDetail } from '../lib/api';
import { renderLoading, renderError, escapeHtml } from '../lib/ui';

export async function renderMahallaDetail(
  container: HTMLElement,
  params: Record<string, string>
): Promise<void> {
  const id = params['id'];
  container.innerHTML = `
    <div class="page-header header-row">
      <div>
        <h1>Mahalla tafsilotlari</h1>
        <p class="mono">${escapeHtml(id ?? '—')}</p>
      </div>
      <a class="btn btn-ghost" href="#/mahallalar">&larr; Ro'yxatga qaytish</a>
    </div>
    <div id="mahalla-detail-body"></div>
  `;
  const body = container.querySelector<HTMLElement>('#mahalla-detail-body')!;

  if (!id) {
    renderError(body, new Error('Mahalla ID topilmadi.'));
    return;
  }

  renderLoading(body);

  try {
    const detail = await api.getMahallaDetail(id);
    body.innerHTML = renderDetail(detail);
  } catch (err) {
    renderError(body, err);
  }
}

function renderDetail(detail: MahallaDetail): string {
  const region = (detail['district'] as string) ?? (detail['region'] as string) ?? '—';
  const status = detail.requestsByStatus ?? { yangi: 0, jarayonda: 0, yakunlandi: 0 };
  const requestsTotal = status.yangi + status.jarayonda + status.yakunlandi || 1;
  const counts = detail.counts ?? {
    announcements: 0,
    events: 0,
    polls: 0,
    serviceAds: 0,
    services: 0,
  };
  const raisName = detail.rais
    ? ((detail.rais['firstName'] as string) ?? '') +
      ' ' +
      ((detail.rais['lastName'] as string) ?? '')
    : '—';

  return `
    <div class="card">
      <h2>Asosiy ma'lumot</h2>
      <div class="table-wrap">
        <table>
          <tbody>
            <tr><td>ID</td><td class="mono">${escapeHtml(detail.id)}</td></tr>
            <tr><td>Nomi</td><td>${escapeHtml((detail['name'] as string) ?? '—')}</td></tr>
            <tr><td>Viloyat/Tuman</td><td>${escapeHtml(region)}</td></tr>
            <tr><td>Rais</td><td>${escapeHtml(raisName.trim() || '—')}</td></tr>
          </tbody>
        </table>
      </div>
    </div>

    <div class="stat-grid">
      <div class="stat-card">
        <div class="stat-label">A'zolar soni</div>
        <div class="stat-value">${escapeHtml(detail.memberCount)}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">E'lonlar</div>
        <div class="stat-value">${escapeHtml(counts.announcements)}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Tadbirlar</div>
        <div class="stat-value">${escapeHtml(counts.events)}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">So'rovnomalar</div>
        <div class="stat-value">${escapeHtml(counts.polls)}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Reklama e'lonlari</div>
        <div class="stat-value">${escapeHtml(counts.serviceAds)}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Xizmatlar</div>
        <div class="stat-value">${escapeHtml(counts.services)}</div>
      </div>
    </div>

    <div class="card">
      <h2>Murojaatlar holati bo'yicha</h2>
      <div class="status-breakdown">
        ${renderStatusBar('Yangi', status.yangi, requestsTotal, 'badge-pending')}
        ${renderStatusBar('Jarayonda', status.jarayonda, requestsTotal, 'badge-pending')}
        ${renderStatusBar('Yakunlandi', status.yakunlandi, requestsTotal, 'badge-success')}
      </div>
    </div>
  `;
}

function renderStatusBar(label: string, value: number, total: number, badgeClass: string): string {
  const pct = Math.round((value / total) * 100);
  return `
    <div class="status-row">
      <span class="badge ${badgeClass}">${escapeHtml(label)}</span>
      <div class="status-track"><div class="status-fill" style="width:${pct}%"></div></div>
      <span class="status-count">${escapeHtml(value)}</span>
    </div>
  `;
}
