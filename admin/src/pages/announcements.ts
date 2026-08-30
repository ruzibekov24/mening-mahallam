import { api, type Announcement, type MahallaEvent, ApiError } from '../lib/api';
import { renderLoading, renderError, renderEmpty, escapeHtml, formatDate } from '../lib/ui';

type Tab = 'announcements' | 'events';

let activeTab: Tab = 'announcements';

export async function renderAnnouncements(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="page-header">
      <div class="header-row">
        <div>
          <h1>E'lonlar va tadbirlar</h1>
          <p>Barcha mahallalar bo'yicha e'lonlar va tadbirlarni ko'rib chiqish</p>
        </div>
        <div class="actions-cell">
          <button class="btn btn-sm" id="tab-announcements" type="button">E'lonlar</button>
          <button class="btn btn-ghost btn-sm" id="tab-events" type="button">Tadbirlar</button>
        </div>
      </div>
    </div>
    <div class="card" id="list-body"></div>
  `;

  const body = container.querySelector<HTMLElement>('#list-body')!;
  const tabAnnouncements = container.querySelector<HTMLButtonElement>('#tab-announcements')!;
  const tabEvents = container.querySelector<HTMLButtonElement>('#tab-events')!;

  function updateTabButtons(): void {
    tabAnnouncements.classList.toggle('btn-ghost', activeTab !== 'announcements');
    tabEvents.classList.toggle('btn-ghost', activeTab !== 'events');
  }

  tabAnnouncements.addEventListener('click', () => {
    activeTab = 'announcements';
    updateTabButtons();
    void load(body);
  });
  tabEvents.addEventListener('click', () => {
    activeTab = 'events';
    updateTabButtons();
    void load(body);
  });

  updateTabButtons();
  await load(body);
}

async function load(body: HTMLElement): Promise<void> {
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
    } else {
      const list = await api.getEvents();
      if (!list.length) {
        renderEmpty(body, "Hozircha tadbirlar mavjud emas.");
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
    }
    body.querySelectorAll<HTMLButtonElement>('[data-action="delete"]').forEach((btn) => {
      btn.addEventListener('click', () => handleDelete(btn, body));
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
        <button class="btn btn-danger btn-sm" data-action="delete" data-mahalla-id="${escapeHtml(e.mahallaId)}" data-id="${escapeHtml(e.id)}">O'chirish</button>
      </td>
    </tr>
  `;
}

async function handleDelete(btn: HTMLButtonElement, body: HTMLElement): Promise<void> {
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
    await load(body);
  } catch (err) {
    const message = err instanceof ApiError ? err.message : "O'chirib bo'lmadi.";
    alert(`Xatolik: ${message}`);
    btn.disabled = false;
    btn.textContent = "O'chirish";
  }
}
