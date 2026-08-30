import { api } from './api';
import { escapeHtml } from './ui';

/**
 * Populates a <select> element with all mahallas (id -> name), for use by
 * any create/edit form that needs to pick a mahalla. Shared across pages
 * so the "which mahalla" UI stays consistent.
 */
export async function populateMahallaSelect(
  select: HTMLSelectElement,
  selectedId?: string
): Promise<void> {
  select.innerHTML = '<option value="">Yuklanmoqda...</option>';
  select.disabled = true;
  try {
    const mahallas = await api.getMahallas();
    if (!mahallas.length) {
      select.innerHTML = '<option value="">Mahallalar topilmadi</option>';
      return;
    }
    select.innerHTML =
      '<option value="">— Mahallani tanlang —</option>' +
      mahallas
        .map(
          (m) =>
            `<option value="${escapeHtml(m.id)}">${escapeHtml(
              (m.name as string) || m.id
            )}</option>`
        )
        .join('');
    if (selectedId) select.value = selectedId;
  } catch {
    select.innerHTML = '<option value="">Mahallalarni yuklab bo\'lmadi</option>';
  } finally {
    select.disabled = false;
  }
}
