import { api, type ServiceAd, ApiError } from '../lib/api';
import { renderLoading, renderError, renderEmpty, escapeHtml, formatDate } from '../lib/ui';

export async function renderXizmatlar(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="page-header">
      <h1>Xizmatlar</h1>
      <p>Barcha mahallalar bo'yicha pullik e'lonlar (xizmat reklamalari)</p>
    </div>
    <div class="card" id="ads-body"></div>
  `;
  const body = container.querySelector<HTMLElement>('#ads-body')!;
  await load(body);
}

async function load(body: HTMLElement): Promise<void> {
  renderLoading(body);
  try {
    const list = await api.getServiceAds();
    if (!list.length) {
      renderEmpty(body, "Hozircha xizmat e'lonlari mavjud emas.");
      return;
    }
    body.innerHTML = `
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Mahalla</th>
              <th>Sarlavha</th>
              <th>Tavsif</th>
              <th>Narx</th>
              <th>Telefon</th>
              <th>Sana</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            ${list.map((a) => renderRow(a)).join('')}
          </tbody>
        </table>
      </div>
    `;
    body.querySelectorAll<HTMLButtonElement>('[data-action="delete"]').forEach((btn) => {
      btn.addEventListener('click', () => handleDelete(btn, body));
    });
  } catch (err) {
    renderError(body, err);
  }
}

function formatPrice(ad: ServiceAd): string {
  const price = ad.price;
  if (typeof price === 'number') return price.toLocaleString('uz-UZ') + " so'm";
  if (typeof price === 'string' && price) return price;
  return '—';
}

function truncate(text: string | undefined, max = 60): string {
  if (!text) return '—';
  return text.length > max ? text.slice(0, max) + '…' : text;
}

function renderRow(a: ServiceAd): string {
  return `
    <tr data-row-id="${escapeHtml(a.id)}">
      <td class="mono">${escapeHtml(a.mahallaId)}</td>
      <td>${escapeHtml(a.title)}</td>
      <td>${escapeHtml(truncate(a.description))}</td>
      <td>${escapeHtml(formatPrice(a))}</td>
      <td class="mono">${escapeHtml(a.phone ?? '—')}</td>
      <td>${formatDate(a.createdAt)}</td>
      <td class="actions-cell">
        <button class="btn btn-danger btn-sm" data-action="delete" data-mahalla-id="${escapeHtml(a.mahallaId)}" data-id="${escapeHtml(a.id)}">O'chirish</button>
      </td>
    </tr>
  `;
}

async function handleDelete(btn: HTMLButtonElement, body: HTMLElement): Promise<void> {
  const id = btn.dataset.id!;
  const mahallaId = btn.dataset.mahallaId!;
  if (!confirm("Ushbu e'lonni o'chirishni tasdiqlaysizmi?")) return;
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner"></span>';
  try {
    await api.deleteServiceAd(mahallaId, id);
    await load(body);
  } catch (err) {
    const message = err instanceof ApiError ? err.message : "O'chirib bo'lmadi.";
    alert(`Xatolik: ${message}`);
    btn.disabled = false;
    btn.textContent = "O'chirish";
  }
}
