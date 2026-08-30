import { api, type MurojaatRequest, ApiError } from '../lib/api';
import { renderLoading, renderError, renderEmpty, escapeHtml, formatDate } from '../lib/ui';

type StatusFilter = 'yangi' | 'jarayonda' | 'yakunlandi' | '';

const STATUS_OPTIONS: { value: StatusFilter; label: string }[] = [
  { value: '', label: 'Hammasi' },
  { value: 'yangi', label: 'Yangi' },
  { value: 'jarayonda', label: 'Jarayonda' },
  { value: 'yakunlandi', label: 'Yakunlandi' },
];

const STATUS_VALUES: MurojaatRequest['status'][] = ['yangi', 'jarayonda', 'yakunlandi'];

let currentFilter: StatusFilter = '';

export async function renderMurojaatlar(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="page-header">
      <h1>Murojaatlar</h1>
      <p>Barcha mahallalar bo'yicha fuqarolar murojaatlarini ko'rib chiqish</p>
    </div>
    <div class="card">
      <div class="field narrow">
        <label for="status-filter">Holat bo'yicha filtr</label>
        <select id="status-filter">
          ${STATUS_OPTIONS.map(
            (o) => `<option value="${o.value}">${escapeHtml(o.label)}</option>`
          ).join('')}
        </select>
      </div>
    </div>
    <div class="card" id="requests-body"></div>
  `;

  const body = container.querySelector<HTMLElement>('#requests-body')!;
  const filterSelect = container.querySelector<HTMLSelectElement>('#status-filter')!;
  filterSelect.value = currentFilter;
  filterSelect.addEventListener('change', () => {
    currentFilter = filterSelect.value as StatusFilter;
    void load(body);
  });

  await load(body);
}

async function load(body: HTMLElement): Promise<void> {
  renderLoading(body);
  try {
    const list = await api.getRequests(currentFilter || undefined);
    if (!list.length) {
      renderEmpty(body, "Murojaatlar topilmadi.");
      return;
    }
    body.innerHTML = `
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Mahalla</th>
              <th>Sarlavha</th>
              <th>Holat</th>
              <th>Muhimlik</th>
              <th>Sana</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            ${list.map((r) => renderRow(r)).join('')}
          </tbody>
        </table>
      </div>
    `;
    body.querySelectorAll<HTMLSelectElement>('[data-status-select]').forEach((select) => {
      select.addEventListener('change', () => handleStatusChange(select, body));
    });
  } catch (err) {
    renderError(body, err);
  }
}

function statusBadgeClass(status: string): string {
  if (status === 'yakunlandi') return 'badge-success';
  if (status === 'yangi') return 'badge-pending';
  return 'badge';
}

function renderRow(r: MurojaatRequest): string {
  return `
    <tr data-row-id="${escapeHtml(r.id)}">
      <td class="mono">${escapeHtml(r.mahallaId)}</td>
      <td>${escapeHtml(r.title)}</td>
      <td><span class="badge ${statusBadgeClass(r.status)}">${escapeHtml(r.status)}</span></td>
      <td>${escapeHtml(r.priority ?? '—')}</td>
      <td>${formatDate(r.createdAt)}</td>
      <td class="actions-cell">
        <select data-status-select data-mahalla-id="${escapeHtml(r.mahallaId)}" data-id="${escapeHtml(r.id)}">
          ${STATUS_VALUES.map(
            (s) =>
              `<option value="${s}" ${s === r.status ? 'selected' : ''}>${escapeHtml(s)}</option>`
          ).join('')}
        </select>
      </td>
    </tr>
  `;
}

async function handleStatusChange(select: HTMLSelectElement, body: HTMLElement): Promise<void> {
  const id = select.dataset.id!;
  const mahallaId = select.dataset.mahallaId!;
  const status = select.value as 'yangi' | 'jarayonda' | 'yakunlandi';
  select.disabled = true;
  try {
    await api.updateRequestStatus(mahallaId, id, status);
    await load(body);
  } catch (err) {
    const message = err instanceof ApiError ? err.message : "Holatni o'zgartirib bo'lmadi.";
    alert(`Xatolik: ${message}`);
    select.disabled = false;
  }
}
