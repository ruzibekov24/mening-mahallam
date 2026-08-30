import { api, type Report, ApiError } from '../lib/api';
import { renderLoading, renderError, renderEmpty, escapeHtml, formatDate } from '../lib/ui';

export async function renderShikoyatlar(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="page-header">
      <h1>Shikoyatlar</h1>
      <p>Kutilayotgan shikoyatlarni ko'rib chiqish</p>
    </div>
    <div class="card" id="reports-body"></div>
  `;
  const body = container.querySelector<HTMLElement>('#reports-body')!;
  await load(body);
}

async function load(body: HTMLElement): Promise<void> {
  renderLoading(body);
  try {
    const list = await api.getReports('pending');
    if (!list.length) {
      renderEmpty(body, "Kutilayotgan shikoyatlar yo'q.");
      return;
    }
    body.innerHTML = `
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Turi</th>
              <th>Sabab</th>
              <th>Mahalla</th>
              <th>Yuborilgan sana</th>
              <th>Holat</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            ${list.map((r) => renderRow(r)).join('')}
          </tbody>
        </table>
      </div>
    `;
    body.querySelectorAll<HTMLButtonElement>('[data-action]').forEach((btn) => {
      btn.addEventListener('click', () => handleResolve(btn, body));
    });
  } catch (err) {
    renderError(body, err);
  }
}

function renderRow(r: Report): string {
  return `
    <tr data-row-id="${escapeHtml(r.id)}">
      <td>${escapeHtml(r.targetType)}</td>
      <td>${escapeHtml(r.reason)}</td>
      <td>${escapeHtml(r.mahallaId ?? '—')}</td>
      <td>${formatDate(r.createdAt)}</td>
      <td><span class="badge badge-pending">${escapeHtml(r.status)}</span></td>
      <td class="actions-cell">
        <button class="btn btn-success btn-sm" data-action="reviewed" data-id="${escapeHtml(r.id)}">Ko'rib chiqildi</button>
        <button class="btn btn-danger btn-sm" data-action="dismissed" data-id="${escapeHtml(r.id)}">Rad etildi</button>
      </td>
    </tr>
  `;
}

async function handleResolve(btn: HTMLButtonElement, body: HTMLElement): Promise<void> {
  const id = btn.dataset.id!;
  const outcome = btn.dataset.action as 'reviewed' | 'dismissed';
  const row = body.querySelector<HTMLTableRowElement>(`tr[data-row-id="${CSS.escape(id)}"]`);
  const buttons = row?.querySelectorAll<HTMLButtonElement>('button') ?? [];
  buttons.forEach((b) => (b.disabled = true));
  btn.innerHTML = '<span class="spinner"></span>';

  try {
    await api.resolveReport(id, outcome);
    await load(body);
  } catch (err) {
    const message = err instanceof ApiError ? err.message : "Amalni bajarib bo'lmadi.";
    alert(`Xatolik: ${message}`);
    buttons.forEach((b) => (b.disabled = false));
    btn.textContent = outcome === 'reviewed' ? "Ko'rib chiqildi" : 'Rad etildi';
  }
}
