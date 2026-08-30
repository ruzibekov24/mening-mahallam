import { api, type PremiumRequest, ApiError } from '../lib/api';
import { renderLoading, renderError, renderEmpty, escapeHtml, formatDate } from '../lib/ui';

export async function renderPremium(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="page-header">
      <h1>Premium so'rovlar</h1>
      <p>Kutilayotgan premium so'rovlarni ko'rib chiqish</p>
    </div>
    <div class="card" id="premium-body"></div>
  `;
  const body = container.querySelector<HTMLElement>('#premium-body')!;
  await load(body);
}

async function load(body: HTMLElement): Promise<void> {
  renderLoading(body);
  try {
    const list = await api.getPremiumRequests('pending');
    if (!list.length) {
      renderEmpty(body, 'Kutilayotgan so\'rovlar yo\'q.');
      return;
    }
    body.innerHTML = `
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Foydalanuvchi</th>
              <th>UID</th>
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
      btn.addEventListener('click', () => handleAction(btn, body));
    });
  } catch (err) {
    renderError(body, err);
  }
}

function renderRow(r: PremiumRequest): string {
  const name = r.displayName || r.phone || '—';
  return `
    <tr data-row-id="${escapeHtml(r.id)}">
      <td>${escapeHtml(name)}</td>
      <td class="mono">${escapeHtml(r.uid)}</td>
      <td>${formatDate(r.createdAt)}</td>
      <td><span class="badge badge-pending">${escapeHtml(r.status)}</span></td>
      <td class="actions-cell">
        <button class="btn btn-success btn-sm" data-action="approve" data-id="${escapeHtml(r.id)}">Tasdiqlash</button>
        <button class="btn btn-danger btn-sm" data-action="reject" data-id="${escapeHtml(r.id)}">Rad etish</button>
      </td>
    </tr>
  `;
}

async function handleAction(btn: HTMLButtonElement, body: HTMLElement): Promise<void> {
  const id = btn.dataset.id!;
  const action = btn.dataset.action as 'approve' | 'reject';
  const row = body.querySelector<HTMLTableRowElement>(`tr[data-row-id="${CSS.escape(id)}"]`);
  const buttons = row?.querySelectorAll<HTMLButtonElement>('button') ?? [];
  buttons.forEach((b) => (b.disabled = true));
  btn.innerHTML = '<span class="spinner"></span>';

  try {
    if (action === 'approve') {
      await api.approvePremiumRequest(id);
    } else {
      await api.rejectPremiumRequest(id);
    }
    await load(body);
  } catch (err) {
    const message = err instanceof ApiError ? err.message : 'Amalni bajarib bo\'lmadi.';
    alert(`Xatolik: ${message}`);
    buttons.forEach((b) => (b.disabled = false));
    btn.textContent = action === 'approve' ? 'Tasdiqlash' : 'Rad etish';
  }
}
