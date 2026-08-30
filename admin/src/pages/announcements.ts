import {
  api,
  type Announcement,
  type MahallaEvent,
  ANNOUNCEMENT_CATEGORIES,
  ApiError,
} from '../lib/api';
import { renderLoading, renderError, renderEmpty, escapeHtml, formatDate } from '../lib/ui';
import { populateMahallaSelect } from '../lib/mahallaSelect';

type Tab = 'announcements' | 'events';

let activeTab: Tab = 'announcements';
let editingAnnouncement: Announcement | null = null;
let editingEvent: MahallaEvent | null = null;

export async function renderAnnouncements(container: HTMLElement): Promise<void> {
  editingAnnouncement = null;
  editingEvent = null;
  container.innerHTML = `
    <div class="page-header">
      <div class="header-row">
        <div>
          <h1>E'lonlar va tadbirlar</h1>
          <p>Barcha mahallalar bo'yicha e'lonlar va tadbirlarni boshqarish</p>
        </div>
        <div class="actions-cell">
          <button class="btn btn-sm" id="tab-announcements" type="button">E'lonlar</button>
          <button class="btn btn-ghost btn-sm" id="tab-events" type="button">Tadbirlar</button>
        </div>
      </div>
    </div>
    <div class="card" id="form-card"></div>
    <div class="card" id="list-body"></div>
  `;

  const body = container.querySelector<HTMLElement>('#list-body')!;
  const formCard = container.querySelector<HTMLElement>('#form-card')!;
  const tabAnnouncements = container.querySelector<HTMLButtonElement>('#tab-announcements')!;
  const tabEvents = container.querySelector<HTMLButtonElement>('#tab-events')!;

  function updateTabButtons(): void {
    tabAnnouncements.classList.toggle('btn-ghost', activeTab !== 'announcements');
    tabEvents.classList.toggle('btn-ghost', activeTab !== 'events');
  }

  tabAnnouncements.addEventListener('click', () => {
    activeTab = 'announcements';
    editingAnnouncement = null;
    editingEvent = null;
    updateTabButtons();
    renderForm(formCard);
    void load(body, formCard);
  });
  tabEvents.addEventListener('click', () => {
    activeTab = 'events';
    editingAnnouncement = null;
    editingEvent = null;
    updateTabButtons();
    renderForm(formCard);
    void load(body, formCard);
  });

  updateTabButtons();
  renderForm(formCard);
  await load(body, formCard);
}

function renderForm(formCard: HTMLElement): void {
  if (activeTab === 'announcements') {
    const editing = editingAnnouncement;
    formCard.innerHTML = `
      <h2 id="form-title">${editing ? "E'lonni tahrirlash" : "Yangi e'lon qo'shish"}</h2>
      <form id="item-form" class="inline-form">
        <div class="field">
          <label for="f-mahallaId">Mahalla</label>
          <select id="f-mahallaId" name="mahallaId" required></select>
        </div>
        <div class="field">
          <label for="f-title">Sarlavha</label>
          <input type="text" id="f-title" name="title" required />
        </div>
        <div class="field">
          <label for="f-category">Kategoriya</label>
          <select id="f-category" name="category" required>
            ${ANNOUNCEMENT_CATEGORIES.map((c) => `<option value="${c.value}">${c.label}</option>`).join('')}
          </select>
        </div>
        <div class="field" style="flex: 1 1 260px;">
          <label for="f-body">Matn</label>
          <textarea id="f-body" name="body" rows="3" required></textarea>
        </div>
        <div class="actions-cell">
          <button type="submit" class="btn" id="f-submit">${editing ? 'Saqlash' : "Qo'shish"}</button>
          <button type="button" class="btn btn-ghost" id="f-cancel" ${editing ? '' : 'hidden'}>Bekor qilish</button>
        </div>
      </form>
      <div id="f-error"></div>
    `;
    const form = formCard.querySelector<HTMLFormElement>('#item-form')!;
    const mahallaSelect = formCard.querySelector<HTMLSelectElement>('#f-mahallaId')!;
    if (editing) {
      (form.elements.namedItem('title') as HTMLInputElement).value = editing.title;
      (form.elements.namedItem('category') as HTMLSelectElement).value = editing.category ?? 'umumiy';
      (form.elements.namedItem('body') as HTMLTextAreaElement).value = editing.body ?? '';
      void populateMahallaSelect(mahallaSelect, editing.mahallaId);
      mahallaSelect.disabled = true;
    } else {
      void populateMahallaSelect(mahallaSelect);
    }
  } else {
    const editing = editingEvent;
    formCard.innerHTML = `
      <h2 id="form-title">${editing ? 'Tadbirni tahrirlash' : 'Yangi tadbir qo\'shish'}</h2>
      <form id="item-form" class="inline-form">
        <div class="field">
          <label for="f-mahallaId">Mahalla</label>
          <select id="f-mahallaId" name="mahallaId" required></select>
        </div>
        <div class="field">
          <label for="f-title">Sarlavha</label>
          <input type="text" id="f-title" name="title" required />
        </div>
        <div class="field">
          <label for="f-dateTime">Sana va vaqt</label>
          <input type="datetime-local" id="f-dateTime" name="dateTime" required />
        </div>
        <div class="field">
          <label for="f-location">Manzil</label>
          <input type="text" id="f-location" name="location" required />
        </div>
        <div class="actions-cell">
          <button type="submit" class="btn" id="f-submit">${editing ? 'Saqlash' : "Qo'shish"}</button>
          <button type="button" class="btn btn-ghost" id="f-cancel" ${editing ? '' : 'hidden'}>Bekor qilish</button>
        </div>
      </form>
      <div id="f-error"></div>
    `;
    const form = formCard.querySelector<HTMLFormElement>('#item-form')!;
    const mahallaSelect = formCard.querySelector<HTMLSelectElement>('#f-mahallaId')!;
    if (editing) {
      (form.elements.namedItem('title') as HTMLInputElement).value = editing.title;
      (form.elements.namedItem('dateTime') as HTMLInputElement).value = toLocalInputValue(editing.dateTime);
      (form.elements.namedItem('location') as HTMLInputElement).value = editing.location ?? '';
      void populateMahallaSelect(mahallaSelect, editing.mahallaId);
      mahallaSelect.disabled = true;
    } else {
      void populateMahallaSelect(mahallaSelect);
    }
  }

  const form = formCard.querySelector<HTMLFormElement>('#item-form')!;
  const formError = formCard.querySelector<HTMLElement>('#f-error')!;
  const cancelBtn = formCard.querySelector<HTMLButtonElement>('#f-cancel')!;

  cancelBtn.addEventListener('click', () => {
    editingAnnouncement = null;
    editingEvent = null;
    renderForm(formCard);
  });

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    formError.innerHTML = '';
    const submitBtn = formCard.querySelector<HTMLButtonElement>('#f-submit')!;
    const mahallaId = (form.elements.namedItem('mahallaId') as HTMLSelectElement).value;
    const title = (form.elements.namedItem('title') as HTMLInputElement).value.trim();

    submitBtn.disabled = true;
    submitBtn.innerHTML = '<span class="spinner"></span>';
    try {
      if (activeTab === 'announcements') {
        const category = (form.elements.namedItem('category') as HTMLSelectElement).value;
        const bodyText = (form.elements.namedItem('body') as HTMLTextAreaElement).value.trim();
        if (!mahallaId || !title || !bodyText) {
          throw new ApiError(400, 'Barcha maydonlarni to\'ldiring.');
        }
        if (editingAnnouncement) {
          await api.updateAnnouncement(editingAnnouncement.mahallaId, editingAnnouncement.id, {
            title,
            body: bodyText,
            category,
          });
        } else {
          await api.createAnnouncement({ mahallaId, title, body: bodyText, category });
        }
      } else {
        const dateTimeRaw = (form.elements.namedItem('dateTime') as HTMLInputElement).value;
        const location = (form.elements.namedItem('location') as HTMLInputElement).value.trim();
        if (!mahallaId || !title || !dateTimeRaw || !location) {
          throw new ApiError(400, 'Barcha maydonlarni to\'ldiring.');
        }
        const dateTime = new Date(dateTimeRaw).toISOString();
        if (editingEvent) {
          await api.updateEvent(editingEvent.mahallaId, editingEvent.id, { title, dateTime, location });
        } else {
          await api.createEvent({ mahallaId, title, dateTime, location });
        }
      }
      editingAnnouncement = null;
      editingEvent = null;
      renderForm(formCard);
      const body = document.getElementById('list-body') as HTMLElement;
      await load(body, formCard);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : 'Saqlab bo\'lmadi.';
      formError.innerHTML = `<div class="error-banner">${escapeHtml(message)}</div>`;
      submitBtn.disabled = false;
      submitBtn.textContent = (activeTab === 'announcements' ? editingAnnouncement : editingEvent)
        ? 'Saqlash'
        : "Qo'shish";
    }
  });
}

function toLocalInputValue(iso: string | undefined): string {
  if (!iso) return '';
  const d = new Date(iso);
  if (isNaN(d.getTime())) return '';
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

async function load(body: HTMLElement, formCard: HTMLElement): Promise<void> {
  renderLoading(body);
  try {
    if (activeTab === 'announcements') {
      const list = await api.getAnnouncements();
      if (!list.length) {
        renderEmpty(body, "Hozircha e'lonlar mavjud emas.");
        return;
      }
      body.innerHTML = `
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Mahalla</th>
                <th>Sarlavha</th>
                <th>Kategoriya</th>
                <th>Sana</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              ${list.map((a) => renderAnnouncementRow(a)).join('')}
            </tbody>
          </table>
        </div>
      `;
      body.querySelectorAll<HTMLButtonElement>('[data-action="edit"]').forEach((btn) => {
        btn.addEventListener('click', () => {
          const id = btn.dataset.id!;
          const item = list.find((a) => a.id === id);
          if (!item) return;
          editingAnnouncement = item;
          renderForm(formCard);
          formCard.scrollIntoView({ behavior: 'smooth', block: 'start' });
        });
      });
    } else {
      const list = await api.getEvents();
      if (!list.length) {
        renderEmpty(body, 'Hozircha tadbirlar mavjud emas.');
        return;
      }
      body.innerHTML = `
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Mahalla</th>
                <th>Sarlavha</th>
                <th>Manzil</th>
                <th>Sana</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              ${list.map((e) => renderEventRow(e)).join('')}
            </tbody>
          </table>
        </div>
      `;
      body.querySelectorAll<HTMLButtonElement>('[data-action="edit"]').forEach((btn) => {
        btn.addEventListener('click', () => {
          const id = btn.dataset.id!;
          const item = list.find((e) => e.id === id);
          if (!item) return;
          editingEvent = item;
          renderForm(formCard);
          formCard.scrollIntoView({ behavior: 'smooth', block: 'start' });
        });
      });
    }
    body.querySelectorAll<HTMLButtonElement>('[data-action="delete"]').forEach((btn) => {
      btn.addEventListener('click', () => handleDelete(btn, body, formCard));
    });
  } catch (err) {
    renderError(body, err);
  }
}

function renderAnnouncementRow(a: Announcement): string {
  return `
    <tr data-row-id="${escapeHtml(a.id)}">
      <td class="mono">${escapeHtml(a.mahallaId)}</td>
      <td>${escapeHtml(a.title)}</td>
      <td>${escapeHtml(a.category ?? '—')}</td>
      <td>${formatDate(a.createdAt)}</td>
      <td class="actions-cell">
        <button class="btn btn-ghost btn-sm" data-action="edit" data-id="${escapeHtml(a.id)}">Tahrirlash</button>
        <button class="btn btn-danger btn-sm" data-action="delete" data-mahalla-id="${escapeHtml(a.mahallaId)}" data-id="${escapeHtml(a.id)}">O'chirish</button>
      </td>
    </tr>
  `;
}

function renderEventRow(e: MahallaEvent): string {
  return `
    <tr data-row-id="${escapeHtml(e.id)}">
      <td class="mono">${escapeHtml(e.mahallaId)}</td>
      <td>${escapeHtml(e.title)}</td>
      <td>${escapeHtml(e.location ?? '—')}</td>
      <td>${formatDate(e.dateTime)}</td>
      <td class="actions-cell">
        <button class="btn btn-ghost btn-sm" data-action="edit" data-id="${escapeHtml(e.id)}">Tahrirlash</button>
        <button class="btn btn-danger btn-sm" data-action="delete" data-mahalla-id="${escapeHtml(e.mahallaId)}" data-id="${escapeHtml(e.id)}">O'chirish</button>
      </td>
    </tr>
  `;
}

async function handleDelete(btn: HTMLButtonElement, body: HTMLElement, formCard: HTMLElement): Promise<void> {
  const id = btn.dataset.id!;
  const mahallaId = btn.dataset.mahallaId!;
  const label = activeTab === 'announcements' ? "e'lonni" : 'tadbirni';
  if (!confirm(`Ushbu ${label} o'chirishni tasdiqlaysizmi?`)) return;
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner"></span>';
  try {
    if (activeTab === 'announcements') {
      await api.deleteAnnouncement(mahallaId, id);
    } else {
      await api.deleteEvent(mahallaId, id);
    }
    await load(body, formCard);
  } catch (err) {
    const message = err instanceof ApiError ? err.message : "O'chirib bo'lmadi.";
    alert(`Xatolik: ${message}`);
    btn.disabled = false;
    btn.textContent = "O'chirish";
  }
}
