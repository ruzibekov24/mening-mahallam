import { api, ApiError, type Mahalla } from '../lib/api';
import { renderLoading, renderError, renderEmpty, escapeHtml } from '../lib/ui';

// Oxirgi yaratilgan mahallaning qo'shilish kodi — bir marta
// ko'rsatilgandan keyin ro'yxat qayta yuklanganda ekranda qoladi
// (rais/admin uni nusxalab olguncha yo'qolib qolmasin deb).
let lastCreatedJoinCode: { mahallaId: string; code: string } | null = null;

export async function renderMahallalar(container: HTMLElement): Promise<void> {
  lastCreatedJoinCode = null;
  container.innerHTML = `
    <div class="page-header">
      <h1>Mahallalar</h1>
      <p>Barcha ro'yxatdan o'tgan mahallalar</p>
    </div>
    <div class="card" id="form-card"></div>
    <div class="card" id="mahallalar-body"></div>
  `;
  const formCard = container.querySelector<HTMLElement>('#form-card')!;
  const body = container.querySelector<HTMLElement>('#mahallalar-body')!;

  renderForm(formCard, body);
  await load(body);
}

function renderForm(formCard: HTMLElement, body: HTMLElement): void {
  formCard.innerHTML = `
    <h2>Yangi mahalla qo'shish</h2>
    <form id="mahalla-form" class="inline-form">
      <div class="field">
        <label for="f-name">Mahalla nomi</label>
        <input type="text" id="f-name" name="name" placeholder="Masalan: Yettiguzar" required />
      </div>
      <div class="field">
        <label for="f-district">Viloyat/Tuman (ixtiyoriy)</label>
        <input type="text" id="f-district" name="district" />
      </div>
      <div class="actions-cell">
        <button type="submit" class="btn" id="f-submit">Qo'shish</button>
      </div>
    </form>
    <p class="hint">
      Nomni lotin harflarida yozing — birinchi harfi qo'shilish kodining
      boshiga ("Y2345678" kabi), qolgan qismi mahalla ID'siga aylanadi.
      Qo'shilish kodi va QR generatsiyasi avtomatik amalga oshadi.
    </p>
    <div id="f-error"></div>
    <div id="f-success"></div>
  `;

  const form = formCard.querySelector<HTMLFormElement>('#mahalla-form')!;
  const formError = formCard.querySelector<HTMLElement>('#f-error')!;
  const formSuccess = formCard.querySelector<HTMLElement>('#f-success')!;

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    formError.innerHTML = '';
    formSuccess.innerHTML = '';
    const submitBtn = formCard.querySelector<HTMLButtonElement>('#f-submit')!;
    const name = (form.elements.namedItem('name') as HTMLInputElement).value.trim();
    const district = (form.elements.namedItem('district') as HTMLInputElement).value.trim();

    if (!name) {
      formError.innerHTML = `<div class="error-banner">Mahalla nomini kiriting.</div>`;
      return;
    }

    submitBtn.disabled = true;
    submitBtn.innerHTML = '<span class="spinner"></span>';
    try {
      const result = await api.createMahalla({ name, district: district || undefined });
      lastCreatedJoinCode = { mahallaId: result.mahalla.id, code: result.joinCode };
      form.reset();
      renderJoinCodeBanner(formSuccess);
      await load(body);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : 'Mahalla yaratib bo\'lmadi.';
      formError.innerHTML = `<div class="error-banner">${escapeHtml(message)}</div>`;
    } finally {
      submitBtn.disabled = false;
      submitBtn.textContent = "Qo'shish";
    }
  });

  renderJoinCodeBanner(formSuccess);
}

function renderJoinCodeBanner(el: HTMLElement): void {
  if (!lastCreatedJoinCode) {
    el.innerHTML = '';
    return;
  }
  el.innerHTML = `
    <div class="success-banner">
      "${escapeHtml(lastCreatedJoinCode.mahallaId)}" yaratildi. Qo'shilish kodi:
      <strong class="mono">${escapeHtml(lastCreatedJoinCode.code)}</strong>
      — buni mahalla raisiga bering (ilovada QR yoki qo'lda kiritish uchun).
    </div>
  `;
}

async function load(body: HTMLElement): Promise<void> {
  renderLoading(body);
  try {
    const list = await api.getMahallas();
    if (!list.length) {
      renderEmpty(body, 'Hozircha mahallalar mavjud emas.');
      return;
    }
    body.innerHTML = `
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Nomi</th>
              <th>Viloyat/Tuman</th>
              <th>A'zolar</th>
            </tr>
          </thead>
          <tbody>
            ${list.map((m) => renderRow(m)).join('')}
          </tbody>
        </table>
      </div>
    `;
    body.querySelectorAll<HTMLTableRowElement>('tr.row-clickable').forEach((row) => {
      row.addEventListener('click', () => {
        const href = row.dataset.href;
        if (href) window.location.hash = href;
      });
    });
  } catch (err) {
    renderError(body, err);
  }
}

function renderRow(m: Mahalla): string {
  const region = (m['region'] as string) ?? (m['district'] as string) ?? '—';
  const members = (m['membersCount'] as number) ?? (m['memberCount'] as number);
  return `
    <tr class="row-clickable" data-href="#/mahallalar/${encodeURIComponent(m.id)}">
      <td class="mono">${escapeHtml(m.id)}</td>
      <td>${escapeHtml(m.name ?? '—')}</td>
      <td>${escapeHtml(region)}</td>
      <td>${members != null ? escapeHtml(members) : '—'}</td>
    </tr>
  `;
}
