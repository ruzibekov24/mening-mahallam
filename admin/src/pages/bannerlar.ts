import { api, type Banner, ApiError } from '../lib/api';
import { renderLoading, renderError, renderEmpty, escapeHtml } from '../lib/ui';

export async function renderBannerlar(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="page-header">
      <h1>Bannerlar</h1>
      <p>Ilovadagi reklama bannerlarini boshqarish</p>
    </div>
    <div class="card">
      <h2>Yangi banner qo'shish</h2>
      <p class="hint">Rasm allaqachon boshqa joyda joylashtirilgan bo'lishi kerak — bu yerda faqat URL manzili kiritiladi.</p>
      <form id="banner-form" class="inline-form">
        <div class="field">
          <label for="imageUrl">Rasm URL</label>
          <input type="url" id="imageUrl" name="imageUrl" placeholder="https://..." required />
        </div>
        <div class="field">
          <label for="linkUrl">Havola URL (ixtiyoriy)</label>
          <input type="url" id="linkUrl" name="linkUrl" placeholder="https://..." />
        </div>
        <div class="field narrow">
          <label for="order">Tartib</label>
          <input type="number" id="order" name="order" value="0" required />
        </div>
        <button type="submit" class="btn" id="banner-submit">Qo'shish</button>
      </form>
      <div id="banner-form-error"></div>
    </div>
    <div class="card" id="banners-body"></div>
  `;

  const body = container.querySelector<HTMLElement>('#banners-body')!;
  const form = container.querySelector<HTMLFormElement>('#banner-form')!;
  const formError = container.querySelector<HTMLElement>('#banner-form-error')!;

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    formError.innerHTML = '';
    const submitBtn = form.querySelector<HTMLButtonElement>('#banner-submit')!;
    const imageUrl = (form.elements.namedItem('imageUrl') as HTMLInputElement).value.trim();
    const linkUrl = (form.elements.namedItem('linkUrl') as HTMLInputElement).value.trim();
    const order = Number((form.elements.namedItem('order') as HTMLInputElement).value || 0);

    submitBtn.disabled = true;
    submitBtn.innerHTML = '<span class="spinner"></span>';
    try {
      await api.createBanner({ imageUrl, linkUrl: linkUrl || undefined, order });
      form.reset();
      (form.elements.namedItem('order') as HTMLInputElement).value = '0';
      await load(body);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : 'Bannerni qo\'shib bo\'lmadi.';
      formError.innerHTML = `<div class="error-banner">${escapeHtml(message)}</div>`;
    } finally {
      submitBtn.disabled = false;
      submitBtn.textContent = "Qo'shish";
    }
  });

  await load(body);
}

async function load(body: HTMLElement): Promise<void> {
  renderLoading(body);
  try {
    const list = await api.getBanners();
    if (!list.length) {
      renderEmpty(body, 'Hozircha bannerlar mavjud emas.');
      return;
    }
    body.innerHTML = `
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Rasm</th>
              <th>Havola</th>
              <th>Tartib</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            ${list.map((b) => renderRow(b)).join('')}
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

function renderRow(b: Banner): string {
  return `
    <tr data-row-id="${escapeHtml(b.id)}">
      <td><a href="${escapeHtml(b.imageUrl)}" target="_blank" rel="noopener noreferrer">${escapeHtml(truncate(b.imageUrl))}</a></td>
      <td>${b.linkUrl ? `<a href="${escapeHtml(b.linkUrl)}" target="_blank" rel="noopener noreferrer">${escapeHtml(truncate(b.linkUrl))}</a>` : '—'}</td>
      <td>${escapeHtml(b.order)}</td>
      <td class="actions-cell">
        <button class="btn btn-danger btn-sm" data-action="delete" data-id="${escapeHtml(b.id)}">O'chirish</button>
      </td>
    </tr>
  `;
}

function truncate(url: string, max = 40): string {
  if (!url) return '—';
  return url.length > max ? url.slice(0, max) + '…' : url;
}

async function handleDelete(btn: HTMLButtonElement, body: HTMLElement): Promise<void> {
  const id = btn.dataset.id!;
  if (!confirm("Ushbu bannerni o'chirishni tasdiqlaysizmi?")) return;
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner"></span>';
  try {
    await api.deleteBanner(id);
    await load(body);
  } catch (err) {
    const message = err instanceof ApiError ? err.message : "O'chirib bo'lmadi.";
    alert(`Xatolik: ${message}`);
    btn.disabled = false;
    btn.textContent = "O'chirish";
  }
}
