import { api, type Banner, ApiError } from '../lib/api';
import { renderLoading, renderError, renderEmpty, escapeHtml } from '../lib/ui';

let editingBanner: Banner | null = null;

export async function renderBannerlar(container: HTMLElement): Promise<void> {
  editingBanner = null;
  container.innerHTML = `
    <div class="page-header">
      <h1>Bannerlar</h1>
      <p>Ilovadagi reklama bannerlarini boshqarish</p>
    </div>
    <div class="card">
      <h2 id="banner-form-title">Yangi banner qo'shish</h2>
      <p class="hint">Rasm allaqachon boshqa joyda joylashtirilgan bo'lishi kerak — bu yerda faqat URL manzili kiritiladi.</p>
      <form id="banner-form" class="inline-form">
        <div class="field">
          <label for="imageUrl">Rasm URL</label>
          <input type="url" id="imageUrl" name="imageUrl" placeholder="https://..." required />
        </div>
        <div class="field">
          <label for="title">Sarlavha</label>
          <input type="text" id="title" name="title" required />
        </div>
        <div class="field" style="flex: 1 1 260px;">
          <label for="description">Tavsif</label>
          <textarea id="description" name="description" rows="2" required></textarea>
        </div>
        <div class="field">
          <label for="linkUrl">Havola URL (ixtiyoriy)</label>
          <input type="url" id="linkUrl" name="linkUrl" placeholder="https://..." />
        </div>
        <div class="field">
          <label for="attribution">Manba (ixtiyoriy)</label>
          <input type="text" id="attribution" name="attribution" placeholder="masalan, CC BY-SA ..." />
        </div>
        <div class="field narrow">
          <label for="order">Tartib</label>
          <input type="number" id="order" name="order" value="0" required />
        </div>
        <div class="actions-cell">
          <button type="submit" class="btn" id="banner-submit">Qo'shish</button>
          <button type="button" class="btn btn-ghost" id="banner-cancel" hidden>Bekor qilish</button>
        </div>
      </form>
      <div id="banner-form-error"></div>
    </div>
    <div class="card" id="banners-body"></div>
  `;

  const body = container.querySelector<HTMLElement>('#banners-body')!;
  const form = container.querySelector<HTMLFormElement>('#banner-form')!;
  const formError = container.querySelector<HTMLElement>('#banner-form-error')!;
  const formTitle = container.querySelector<HTMLElement>('#banner-form-title')!;
  const submitBtn = container.querySelector<HTMLButtonElement>('#banner-submit')!;
  const cancelBtn = container.querySelector<HTMLButtonElement>('#banner-cancel')!;

  cancelBtn.addEventListener('click', () => {
    editingBanner = null;
    form.reset();
    (form.elements.namedItem('order') as HTMLInputElement).value = '0';
    formTitle.textContent = "Yangi banner qo'shish";
    submitBtn.textContent = "Qo'shish";
    cancelBtn.hidden = true;
    formError.innerHTML = '';
  });

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    formError.innerHTML = '';
    const imageUrl = (form.elements.namedItem('imageUrl') as HTMLInputElement).value.trim();
    const title = (form.elements.namedItem('title') as HTMLInputElement).value.trim();
    const description = (form.elements.namedItem('description') as HTMLTextAreaElement).value.trim();
    const linkUrl = (form.elements.namedItem('linkUrl') as HTMLInputElement).value.trim();
    const attribution = (form.elements.namedItem('attribution') as HTMLInputElement).value.trim();
    const order = Number((form.elements.namedItem('order') as HTMLInputElement).value || 0);

    if (!imageUrl || !title || !description) {
      formError.innerHTML = '<div class="error-banner">Rasm URL, sarlavha va tavsif majburiy.</div>';
      return;
    }

    submitBtn.disabled = true;
    submitBtn.innerHTML = '<span class="spinner"></span>';
    try {
      if (editingBanner) {
        await api.updateBanner(editingBanner.id, {
          imageUrl,
          title,
          description,
          order,
          linkUrl: linkUrl || undefined,
          attribution: attribution || undefined,
        });
      } else {
        await api.createBanner({
          imageUrl,
          title,
          description,
          linkUrl: linkUrl || undefined,
          order,
          attribution: attribution || undefined,
        });
      }
      editingBanner = null;
      form.reset();
      (form.elements.namedItem('order') as HTMLInputElement).value = '0';
      formTitle.textContent = "Yangi banner qo'shish";
      submitBtn.textContent = "Qo'shish";
      cancelBtn.hidden = true;
      await load(body, container);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : 'Bannerni saqlab bo\'lmadi.';
      formError.innerHTML = `<div class="error-banner">${escapeHtml(message)}</div>`;
    } finally {
      submitBtn.disabled = false;
      submitBtn.textContent = editingBanner ? 'Saqlash' : "Qo'shish";
    }
  });

  await load(body, container);
}

async function load(body: HTMLElement, container: HTMLElement): Promise<void> {
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
              <th>Sarlavha</th>
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
    body.querySelectorAll<HTMLButtonElement>('[data-action="edit"]').forEach((btn) => {
      btn.addEventListener('click', () => handleEdit(btn, list, container));
    });
    body.querySelectorAll<HTMLButtonElement>('[data-action="delete"]').forEach((btn) => {
      btn.addEventListener('click', () => handleDelete(btn, body, container));
    });
  } catch (err) {
    renderError(body, err);
  }
}

function renderRow(b: Banner): string {
  return `
    <tr data-row-id="${escapeHtml(b.id)}">
      <td><a href="${escapeHtml(b.imageUrl)}" target="_blank" rel="noopener noreferrer">${escapeHtml(truncate(b.imageUrl))}</a></td>
      <td>${escapeHtml(b.title ?? '—')}</td>
      <td>${b.linkUrl ? `<a href="${escapeHtml(b.linkUrl)}" target="_blank" rel="noopener noreferrer">${escapeHtml(truncate(b.linkUrl))}</a>` : '—'}</td>
      <td>${escapeHtml(b.order)}</td>
      <td class="actions-cell">
        <button class="btn btn-ghost btn-sm" data-action="edit" data-id="${escapeHtml(b.id)}">Tahrirlash</button>
        <button class="btn btn-danger btn-sm" data-action="delete" data-id="${escapeHtml(b.id)}">O'chirish</button>
      </td>
    </tr>
  `;
}

function truncate(url: string, max = 40): string {
  if (!url) return '—';
  return url.length > max ? url.slice(0, max) + '…' : url;
}

function handleEdit(btn: HTMLButtonElement, list: Banner[], container: HTMLElement): void {
  const id = btn.dataset.id!;
  const banner = list.find((b) => b.id === id);
  if (!banner) return;
  editingBanner = banner;

  const form = container.querySelector<HTMLFormElement>('#banner-form')!;
  const formTitle = container.querySelector<HTMLElement>('#banner-form-title')!;
  const submitBtn = container.querySelector<HTMLButtonElement>('#banner-submit')!;
  const cancelBtn = container.querySelector<HTMLButtonElement>('#banner-cancel')!;

  formTitle.textContent = `Bannerni tahrirlash: ${banner.title ?? banner.id}`;
  submitBtn.textContent = 'Saqlash';
  cancelBtn.hidden = false;
  (form.elements.namedItem('imageUrl') as HTMLInputElement).value = banner.imageUrl;
  (form.elements.namedItem('title') as HTMLInputElement).value = banner.title ?? '';
  (form.elements.namedItem('description') as HTMLTextAreaElement).value = banner.description ?? '';
  (form.elements.namedItem('linkUrl') as HTMLInputElement).value = banner.linkUrl ?? '';
  (form.elements.namedItem('attribution') as HTMLInputElement).value = banner.attribution ?? '';
  (form.elements.namedItem('order') as HTMLInputElement).value = String(banner.order ?? 0);

  form.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

async function handleDelete(btn: HTMLButtonElement, body: HTMLElement, container: HTMLElement): Promise<void> {
  const id = btn.dataset.id!;
  if (!confirm("Ushbu bannerni o'chirishni tasdiqlaysizmi?")) return;
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner"></span>';
  try {
    await api.deleteBanner(id);
    await load(body, container);
  } catch (err) {
    const message = err instanceof ApiError ? err.message : "O'chirib bo'lmadi.";
    alert(`Xatolik: ${message}`);
    btn.disabled = false;
    btn.textContent = "O'chirish";
  }
}
