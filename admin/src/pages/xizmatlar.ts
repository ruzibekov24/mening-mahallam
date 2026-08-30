import { api, type ServiceAd, ApiError } from '../lib/api';
import { renderLoading, renderError, renderEmpty, escapeHtml, formatDate } from '../lib/ui';
import { populateMahallaSelect } from '../lib/mahallaSelect';

let editingAd: ServiceAd | null = null;

export async function renderXizmatlar(container: HTMLElement): Promise<void> {
  editingAd = null;
  container.innerHTML = `
    <div class="page-header">
      <h1>Reklama e'lonlari</h1>
      <p>Barcha mahallalar bo'yicha pullik e'lonlar (xizmat reklamalari)</p>
    </div>
    <div class="card" id="ad-form-card">
      <h2 id="ad-form-title">Yangi e'lon qo'shish</h2>
      <form id="ad-form" class="inline-form">
        <div class="field">
          <label for="ad-mahallaId">Mahalla</label>
          <select id="ad-mahallaId" name="mahallaId" required></select>
        </div>
        <div class="field">
          <label for="ad-title">Sarlavha</label>
          <input type="text" id="ad-title" name="title" required />
        </div>
        <div class="field">
          <label for="ad-ownerName">Egasi</label>
          <input type="text" id="ad-ownerName" name="ownerName" required />
        </div>
        <div class="field">
          <label for="ad-phone">Telefon</label>
          <input type="tel" id="ad-phone" name="phone" required />
        </div>
        <div class="field narrow">
          <label for="ad-durationDays">Amal qilish muddati (kun)</label>
          <input type="number" id="ad-durationDays" name="durationDays" value="7" min="1" />
        </div>
        <div class="field" style="flex: 1 1 260px;">
          <label for="ad-description">Tavsif</label>
          <textarea id="ad-description" name="description" rows="2" required></textarea>
        </div>
        <div class="actions-cell">
          <button type="submit" class="btn" id="ad-submit">Qo'shish</button>
          <button type="button" class="btn btn-ghost" id="ad-cancel" hidden>Bekor qilish</button>
        </div>
      </form>
      <div id="ad-form-error"></div>
    </div>
    <div class="card" id="ads-body"></div>
  `;
  const body = container.querySelector<HTMLElement>('#ads-body')!;
  const form = container.querySelector<HTMLFormElement>('#ad-form')!;
  const formError = container.querySelector<HTMLElement>('#ad-form-error')!;
  const formTitle = container.querySelector<HTMLElement>('#ad-form-title')!;
  const submitBtn = container.querySelector<HTMLButtonElement>('#ad-submit')!;
  const cancelBtn = container.querySelector<HTMLButtonElement>('#ad-cancel')!;
  const mahallaSelect = container.querySelector<HTMLSelectElement>('#ad-mahallaId')!;

  void populateMahallaSelect(mahallaSelect);

  cancelBtn.addEventListener('click', () => {
    editingAd = null;
    form.reset();
    (form.elements.namedItem('durationDays') as HTMLInputElement).value = '7';
    formTitle.textContent = "Yangi e'lon qo'shish";
    submitBtn.textContent = "Qo'shish";
    cancelBtn.hidden = true;
    mahallaSelect.disabled = false;
    formError.innerHTML = '';
  });

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    formError.innerHTML = '';
    const title = (form.elements.namedItem('title') as HTMLInputElement).value.trim();
    const ownerName = (form.elements.namedItem('ownerName') as HTMLInputElement).value.trim();
    const phone = (form.elements.namedItem('phone') as HTMLInputElement).value.trim();
    const description = (form.elements.namedItem('description') as HTMLTextAreaElement).value.trim();
    const durationDaysRaw = (form.elements.namedItem('durationDays') as HTMLInputElement).value;
    const durationDays = durationDaysRaw ? Number(durationDaysRaw) : undefined;
    const mahallaId = (form.elements.namedItem('mahallaId') as HTMLSelectElement).value;

    if (!mahallaId || !title || !ownerName || !phone || !description) {
      formError.innerHTML = '<div class="error-banner">Barcha maydonlarni to\'ldiring.</div>';
      return;
    }

    submitBtn.disabled = true;
    submitBtn.innerHTML = '<span class="spinner"></span>';
    try {
      if (editingAd) {
        await api.updateServiceAd(editingAd.mahallaId, editingAd.id, {
          title,
          ownerName,
          phone,
          description,
          durationDays,
        });
      } else {
        await api.createServiceAd({ mahallaId, title, ownerName, phone, description, durationDays });
      }
      editingAd = null;
      form.reset();
      (form.elements.namedItem('durationDays') as HTMLInputElement).value = '7';
      formTitle.textContent = "Yangi e'lon qo'shish";
      cancelBtn.hidden = true;
      mahallaSelect.disabled = false;
      await load(body, container);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "E'lonni saqlab bo'lmadi.";
      formError.innerHTML = `<div class="error-banner">${escapeHtml(message)}</div>`;
    } finally {
      submitBtn.disabled = false;
      submitBtn.textContent = editingAd ? 'Saqlash' : "Qo'shish";
    }
  });

  await load(body, container);
}

async function load(body: HTMLElement, container: HTMLElement): Promise<void> {
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
              <th>Egasi</th>
              <th>Telefon</th>
              <th>Amal qilish muddati</th>
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

function renderRow(a: ServiceAd): string {
  const expired = Boolean(a.activeUntil && new Date(a.activeUntil).getTime() < Date.now());
  return `
    <tr data-row-id="${escapeHtml(a.id)}">
      <td class="mono">${escapeHtml(a.mahallaId)}</td>
      <td>${escapeHtml(a.title)}</td>
      <td>${escapeHtml(a.ownerName ?? '—')}</td>
      <td class="mono">${escapeHtml(a.phone ?? '—')}</td>
      <td>${formatDate(a.activeUntil)} ${expired ? '<span class="badge badge-danger">Muddati tugagan</span>' : '<span class="badge badge-success">Faol</span>'}</td>
      <td>${formatDate(a.createdAt)}</td>
      <td class="actions-cell">
        <button class="btn btn-ghost btn-sm" data-action="edit" data-id="${escapeHtml(a.id)}">Tahrirlash</button>
        <button class="btn btn-danger btn-sm" data-action="delete" data-mahalla-id="${escapeHtml(a.mahallaId)}" data-id="${escapeHtml(a.id)}">O'chirish</button>
      </td>
    </tr>
  `;
}

function handleEdit(btn: HTMLButtonElement, list: ServiceAd[], container: HTMLElement): void {
  const id = btn.dataset.id!;
  const ad = list.find((a) => a.id === id);
  if (!ad) return;
  editingAd = ad;

  const form = container.querySelector<HTMLFormElement>('#ad-form')!;
  const formTitle = container.querySelector<HTMLElement>('#ad-form-title')!;
  const submitBtn = container.querySelector<HTMLButtonElement>('#ad-submit')!;
  const cancelBtn = container.querySelector<HTMLButtonElement>('#ad-cancel')!;
  const mahallaSelect = container.querySelector<HTMLSelectElement>('#ad-mahallaId')!;

  formTitle.textContent = `E'lonni tahrirlash: ${ad.title}`;
  submitBtn.textContent = 'Saqlash';
  cancelBtn.hidden = false;
  (form.elements.namedItem('title') as HTMLInputElement).value = ad.title;
  (form.elements.namedItem('ownerName') as HTMLInputElement).value = ad.ownerName ?? '';
  (form.elements.namedItem('phone') as HTMLInputElement).value = ad.phone ?? '';
  (form.elements.namedItem('description') as HTMLTextAreaElement).value = ad.description ?? '';
  (form.elements.namedItem('durationDays') as HTMLInputElement).value = '';
  void populateMahallaSelect(mahallaSelect, ad.mahallaId);
  mahallaSelect.disabled = true;

  form.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

async function handleDelete(btn: HTMLButtonElement, body: HTMLElement, container: HTMLElement): Promise<void> {
  const id = btn.dataset.id!;
  const mahallaId = btn.dataset.mahallaId!;
  if (!confirm("Ushbu e'lonni o'chirishni tasdiqlaysizmi?")) return;
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner"></span>';
  try {
    await api.deleteServiceAd(mahallaId, id);
    await load(body, container);
  } catch (err) {
    const message = err instanceof ApiError ? err.message : "O'chirib bo'lmadi.";
    alert(`Xatolik: ${message}`);
    btn.disabled = false;
    btn.textContent = "O'chirish";
  }
}
