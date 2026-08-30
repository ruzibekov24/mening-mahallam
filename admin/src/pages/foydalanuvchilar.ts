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

function renderRow(u: AdminUser): string {
  return `
    <tr data-row-id="${escapeHtml(u.id)}">
      <td>${escapeHtml(fullName(u))}</td>
      <td class="mono">${escapeHtml(u.phone ?? '—')}</td>
      <td>${escapeHtml(u.role)}</td>
      <td class="mono">${escapeHtml(u.mahallaId ?? '—')}</td>
      <td class="actions-cell">
        <select data-role-select data-uid="${escapeHtml(u.id)}">
          ${ROLE_OPTIONS.map(
            (o) =>
              `<option value="${o.value}" ${o.value === u.role ? 'selected' : ''}>${escapeHtml(o.label)}</option>`
          ).join('')}
        </select>
      </td>
    </tr>
  `;
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
