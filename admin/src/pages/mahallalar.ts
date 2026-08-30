import { api, type Mahalla } from '../lib/api';
import { renderLoading, renderError, renderEmpty, escapeHtml } from '../lib/ui';

export async function renderMahallalar(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="page-header">
      <h1>Mahallalar</h1>
      <p>Barcha ro'yxatdan o'tgan mahallalar</p>
    </div>
    <div class="card" id="mahallalar-body"></div>
  `;
  const body = container.querySelector<HTMLElement>('#mahallalar-body')!;
  renderLoading(body);

  try {
    const list = await api.getMahallas();
    if (!list.length) {
      renderEmpty(body, 'Hozircha mahallalar mavjud emas.');
      return;
    }
    body.innerHTML = `
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Nomi</th>
              <th>Viloyat/Tuman</th>
              <th>A'zolar</th>
            </tr>
          </thead>
          <tbody>
            ${list.map((m) => renderRow(m)).join('')}
          </tbody>
        </table>
      </div>
    `;
  } catch (err) {
    renderError(body, err);
  }
}

function renderRow(m: Mahalla): string {
  const region = (m['region'] as string) ?? (m['district'] as string) ?? '—';
  const members = (m['membersCount'] as number) ?? (m['memberCount'] as number);
  return `
    <tr>
      <td class="mono">${escapeHtml(m.id)}</td>
      <td>${escapeHtml(m.name ?? '—')}</td>
      <td>${escapeHtml(region)}</td>
      <td>${members != null ? escapeHtml(members) : '—'}</td>
    </tr>
  `;
}
