import { api, type LocalService, SERVICE_CATEGORIES, ApiError } from '../lib/api';
import { renderLoading, renderError, renderEmpty, escapeHtml, formatDate } from '../lib/ui';
import { populateMahallaSelect } from '../lib/mahallaSelect';

let editingService: LocalService | null = null;

export async function renderXizmatlarRoyxati(container: HTMLElement): Promise<void> {
  editingService = null;
  container.innerHTML = `
    <div class="page-header">
      <h1>Xizmatlar</h1>
      <p>Mahalladagi mahalliy xizmat ko'rsatuvchilar ro'yxati (santexnik, elektrik va h.k.)</p>
    </div>
    <div class="card" id="service-form-card">
      <h2 id="service-form-title">Yangi xizmat qo'shish</h2>
      <form id="service-form" class="inline-form">
        <div class="field">
          <label for="service-mahallaId">Mahalla</label>
          <select id="service-mahallaId" name="mahallaId" required></select>
        </div>
        <div class="field">
          <label for="service-name">Ism / tashkilot</label>
          <input type="text" id="service-name" name="name" required />
        </div>
        <div class="field">
          <label for="service-category">Kategoriya</label>
          <select id="service-category" name="category" required>
            ${SERVICE_CATEGORIES.map((c) => `<option value="${c.value}">${c.label}</option>`).join('')}
          </select>
        </div>
        <div class="field">
          <label for="service-phone">Telefon</label>
          <input type="tel" id="service-phone" name="phone" required />
        </div>
        <div class="field" style="flex: 1 1 260px;">
          <label for="service-description">Tavsif</label>
          <textarea id="service-description" name="description" rows="2" required></textarea>
        </div>
        <div class="actions-cell">
          <button type="submit" class="btn" id="service-submit">Qo'shish</button>
          <button type="button" class="btn btn-ghost" id="service-cancel" hidden>Bekor qilish</button>
        </div>
      </form>
      <div id="service-form-error"></div>
    </div>
    <div class="card" id="services-body"></div>
  `;

  const body = container.querySelector<HTMLElement>('#services-body')!;
  const form = container.querySelector<HTMLFormElement>('#service-form')!;
  const formError = container.querySelector<HTMLElement>('#service-form-error')!;
  const formTitle = container.querySelector<HTMLElement>('#service-form-title')!;
  const submitBtn = container.querySelector<HTMLButtonElement>('#service-submit')!;
  const cancelBtn = container.querySelector<HTMLButtonElement>('#service-cancel')!;
  const mahallaSelect = container.querySelector<HTMLSelectElement>('#service-mahallaId')!;

  void populateMahallaSelect(mahallaSelect);

  cancelBtn.addEventListener('click', () => {
    editingService = null;
    form.reset();
    formTitle.textContent = "Yangi xizmat qo'shish";
    submitBtn.textContent = "Qo'shish";
    cancelBtn.hidden = true;
    formError.innerHTML = '';
  });

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    formError.innerHTML = '';
    const name = (form.elements.namedItem('name') as HTMLInputElement).value.trim();
    const category = (form.elements.namedItem('category') as HTMLSelectElement).value;
    const phone = (form.elements.namedItem('phone') as HTMLInputElement).value.trim();
    const description = (form.elements.namedItem('description') as HTMLTextAreaElement).value.trim();
    const mahallaId = (form.elements.namedItem('mahallaId') as HTMLSelectElement).value;

    if (!mahallaId || !name || !category || !phone || !description) {
      formError.innerHTML = '<div class="error-banner">Barcha maydonlarni to\'ldiring.</div>';
      return;
    }

    submitBtn.disabled = true;
    submitBtn.innerHTML = '<span class="spinner"></span>';
    try {
      if (editingService) {
        await api.updateService(editingService.mahallaId, editingService.id, {
          name,
          category,
          phone,
          description,
        });
      } else {
        await api.createService({ mahallaId, name, category, phone, description });
      }
      editingService = null;
      form.reset();
      formTitle.textContent = "Yangi xizmat qo'shish";
      cancelBtn.hidden = true;
      await load(body, container);
    } catch (err) {
      const message =
        err instanceof ApiError ? err.message : "Xizmatni saqlab bo'lmadi.";
      formError.innerHTML = `<div class="error-banner">${escapeHtml(message)}</div>`;
    } finally {
      submitBtn.disabled = false;
      submitBtn.textContent = editingService ? 'Saqlash' : "Qo'shish";
    }
  });

  await load(body, container);
}

async function load(body: HTMLElement, container: HTMLElement): Promise<void> {
  renderLoading(body);
  try {
    const list = await api.getServices();
    if (!list.length) {
      renderEmpty(body, 'Hozircha xizmatlar mavjud emas.');
      return;
    }
    body.innerHTML = `
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Mahalla</th>
              <th>Ism</th>
              <th>Kategoriya</th>
              <th>Telefon</th>
              <th>Tavsif</th>
              <th>Sana</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            ${list.map((s) => renderRow(s)).join('')}
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

function categoryLabel(value: string): string {
  return SERVICE_CATEGORIES.find((c) => c.value === value)?.label ?? value;
}

function truncate(text: string | undefined, max = 60): string {
  if (!text) return '—';
  return text.length > max ? text.slice(0, max) + '…' : text;
}

function renderRow(s: LocalService): string {
  return `
    <tr data-row-id="${escapeHtml(s.id)}">
      <td class="mono">${escapeHtml(s.mahallaId)}</td>
      <td>${escapeHtml(s.name)}</td>
      <td>${escapeHtml(categoryLabel(s.category))}</td>
      <td class="mono">${escapeHtml(s.phone)}</td>
      <td>${escapeHtml(truncate(s.description))}</td>
      <td>${formatDate(s.createdAt)}</td>
      <td class="actions-cell">
        <button class="btn btn-ghost btn-sm" data-action="edit" data-id="${escapeHtml(s.id)}">Tahrirlash</button>
        <button class="btn btn-danger btn-sm" data-action="delete" data-mahalla-id="${escapeHtml(s.mahallaId)}" data-id="${escapeHtml(s.id)}">O'chirish</button>
      </td>
    </tr>
  `;
}

function handleEdit(btn: HTMLButtonElement, list: LocalService[], container: HTMLElement): void {
  const id = btn.dataset.id!;
  const service = list.find((s) => s.id === id);
  if (!service) return;
  editingService = service;

  const form = container.querySelector<HTMLFormElement>('#service-form')!;
  const formTitle = container.querySelector<HTMLElement>('#service-form-title')!;
  const submitBtn = container.querySelector<HTMLButtonElement>('#service-submit')!;
  const cancelBtn = container.querySelector<HTMLButtonElement>('#service-cancel')!;
  const mahallaSelect = container.querySelector<HTMLSelectElement>('#service-mahallaId')!;

  formTitle.textContent = `Xizmatni tahrirlash: ${service.name}`;
  submitBtn.textContent = 'Saqlash';
  cancelBtn.hidden = false;
  (form.elements.namedItem('name') as HTMLInputElement).value = service.name;
  (form.elements.namedItem('category') as HTMLSelectElement).value = service.category;
  (form.elements.namedItem('phone') as HTMLInputElement).value = service.phone;
  (form.elements.namedItem('description') as HTMLTextAreaElement).value = service.description ?? '';
  void populateMahallaSelect(mahallaSelect, service.mahallaId);
  mahallaSelect.disabled = true;

  form.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

async function handleDelete(btn: HTMLButtonElement, body: HTMLElement, container: HTMLElement): Promise<void> {
  const id = btn.dataset.id!;
  const mahallaId = btn.dataset.mahallaId!;
  if (!confirm("Ushbu xizmatni o'chirishni tasdiqlaysizmi?")) return;
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner"></span>';
  try {
    await api.deleteService(mahallaId, id);
    await load(body, container);
  } catch (err) {
    const message = err instanceof ApiError ? err.message : "O'chirib bo'lmadi.";
    alert(`Xatolik: ${message}`);
    btn.disabled = false;
    btn.textContent = "O'chirish";
  }
}
