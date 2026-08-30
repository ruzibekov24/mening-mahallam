import { api, type AdminUser, ApiError } from '../lib/api';
import { renderLoading, renderError, renderEmpty, escapeHtml } from '../lib/ui';

const ROLE_OPTIONS: { value: string; label: string }[] = [
  { value: 'citizen', label: 'Fuqaro' },
  { value: 'staff', label: 'Xodim' },
  { value: 'rais', label: 'Rais' },
  { value: 'superAdmin', label: 'Super-admin' },
];

export async function renderFoydalanuvchilar(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="page-header">
      <h1>Foydalanuvchilar</h1>
      <p>Foydalanuvchilarni qidirish va rolini boshqarish</p>
    </div>
    <div class="card">
      <form id="search-form" class="inline-form">
        <div class="field">
          <label for="search-input">Qidiruv</label>
          <input type="text" id="search-input" name="search" placeholder="Telefon yoki ism (boshidan)..." required />
        </div>
        <button type="submit" class="btn" id="search-submit">Qidirish</button>
      </form>
      <p class="hint">Qidiruv faqat boshidan mos kelishi bo'yicha ishlaydi (prefix-match): telefon raqami "+" yoki raqam bilan boshlansa telefon bo'yicha, aks holda ism (firstName) bo'yicha qidiriladi.</p>
    </div>
    <div class="card" id="users-body"></div>
  `;

  const body = container.querySelector<HTMLElement>('#users-body')!;
  const form = container.querySelector<HTMLFormElement>('#search-form')!;
  const input = container.querySelector<HTMLInputElement>('#search-input')!;

  renderEmpty(body, "Qidiruv natijalarini ko'rish uchun yuqorida qidiruv so'zini kiriting.");

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const query = input.value.trim();
    if (!query) return;
    const submitBtn = form.querySelector<HTMLButtonElement>('#search-submit')!;
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<span class="spinner"></span>';
    renderLoading(body);
    try {
      const result = await api.searchUsers(query);
      if (!result.users.length) {
        renderEmpty(body, "Hech narsa topilmadi.");
      } else {
        body.innerHTML = `
          <p class="hint">Qidirilgan maydon: <span class="mono">${escapeHtml(result.searchedField)}</span></p>
          <div class="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Ism</th>
                  <th>Telefon</th>
                  <th>Rol</th>
                  <th>Mahalla</th>
                  <th>Premium</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                ${result.users.map((u) => renderRow(u)).join('')}
              </tbody>
            </table>
          </div>
        `;
        body.querySelectorAll<HTMLSelectElement>('[data-role-select]').forEach((select) => {
          select.addEventListener('change', () => handleRoleChange(select));
        });
        body.querySelectorAll<HTMLButtonElement>('[data-action="grant-premium"]').forEach((btn) => {
          btn.addEventListener('click', () => handleGrantPremium(btn, body));
        });
        body.querySelectorAll<HTMLButtonElement>('[data-action="revoke-premium"]').forEach((btn) => {
          btn.addEventListener('click', () => handleRevokePremium(btn, body));
        });
      }
    } catch (err) {
      renderError(body, err);
    } finally {
      submitBtn.disabled = false;
      submitBtn.textContent = 'Qidirish';
    }
  });
}

function fullName(u: AdminUser): string {
  const name = [u.firstName, u.lastName].filter(Boolean).join(' ').trim();
  return name || '—';
}

function premiumStatus(u: AdminUser): string {
  if (!('premiumUntil' in u)) return '';
  const until = u.premiumUntil;
  if (!until) return '<span class="badge">Premium yo\'q</span>';
  const isActive = new Date(until as string).getTime() > Date.now();
  return isActive
    ? `<span class="badge badge-success">Premium: ${escapeHtml(new Date(until as string).toLocaleDateString('uz-UZ'))} gacha</span>`
    : `<span class="badge badge-danger">Premium tugagan</span>`;
}

function renderRow(u: AdminUser): string {
  return `
    <tr data-row-id="${escapeHtml(u.id)}">
      <td>${escapeHtml(fullName(u))}</td>
      <td class="mono">${escapeHtml(u.phone ?? '—')}</td>
      <td>${escapeHtml(u.role)}</td>
      <td class="mono">${escapeHtml(u.mahallaId ?? '—')}</td>
      <td>${premiumStatus(u)}</td>
      <td class="actions-cell">
        <select data-role-select data-uid="${escapeHtml(u.id)}">
          ${ROLE_OPTIONS.map(
            (o) =>
              `<option value="${o.value}" ${o.value === u.role ? 'selected' : ''}>${escapeHtml(o.label)}</option>`
          ).join('')}
        </select>
        <button class="btn btn-success btn-sm" data-action="grant-premium" data-uid="${escapeHtml(u.id)}">Premium berish</button>
        <button class="btn btn-ghost btn-sm" data-action="revoke-premium" data-uid="${escapeHtml(u.id)}">Premium olib tashlash</button>
      </td>
    </tr>
  `;
}

async function handleGrantPremium(btn: HTMLButtonElement, body: HTMLElement): Promise<void> {
  const uid = btn.dataset.uid!;
  const input = prompt('Necha oyga premium berilsin?', '1');
  if (input === null) return;
  const months = Number(input);
  if (!Number.isInteger(months) || months <= 0) {
    alert("Oylar soni musbat butun son bo'lishi kerak.");
    return;
  }
  btn.disabled = true;
  const original = btn.textContent;
  btn.innerHTML = '<span class="spinner"></span>';
  try {
    await api.grantPremium(uid, months);
    const row = btn.closest('tr');
    row?.querySelectorAll<HTMLButtonElement>('button').forEach((b) => (b.disabled = false));
    alert('Premium muvaffaqiyatli berildi.');
  } catch (err) {
    const message = err instanceof ApiError ? err.message : "Premium berib bo'lmadi.";
    alert(`Xatolik: ${message}`);
  } finally {
    btn.disabled = false;
    btn.textContent = original;
    void body;
  }
}

async function handleRevokePremium(btn: HTMLButtonElement, body: HTMLElement): Promise<void> {
  const uid = btn.dataset.uid!;
  if (!confirm("Ushbu foydalanuvchidan premiumni olib tashlashni tasdiqlaysizmi?")) return;
  btn.disabled = true;
  const original = btn.textContent;
  btn.innerHTML = '<span class="spinner"></span>';
  try {
    await api.revokePremium(uid);
    alert('Premium olib tashlandi.');
  } catch (err) {
    const message = err instanceof ApiError ? err.message : "Premium olib tashlab bo'lmadi.";
    alert(`Xatolik: ${message}`);
  } finally {
    btn.disabled = false;
    btn.textContent = original;
    void body;
  }
}

async function handleRoleChange(select: HTMLSelectElement): Promise<void> {
  const uid = select.dataset.uid!;
  const role = select.value as 'citizen' | 'staff' | 'rais' | 'superAdmin';
  const previousValue =
    Array.from(select.options).find((o) => o.defaultSelected)?.value ?? select.value;
  if (role === 'superAdmin' && !confirm("Foydalanuvchiga Super-admin huquqini berishni tasdiqlaysizmi?")) {
    select.value = previousValue;
    return;
  }
  select.disabled = true;
  try {
    await api.updateUserRole(uid, role);
    select.querySelectorAll('option').forEach((o) => (o.defaultSelected = o.selected));
  } catch (err) {
    const message = err instanceof ApiError ? err.message : "Rolni o'zgartirib bo'lmadi.";
    alert(`Xatolik: ${message}`);
    select.value = previousValue;
  } finally {
    select.disabled = false;
  }
}
