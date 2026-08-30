import { ApiError } from './api';

export function renderLoading(container: HTMLElement, label = 'Yuklanmoqda...'): void {
  container.innerHTML = `<div class="state-msg"><span class="spinner"></span> ${label}</div>`;
}

export function renderError(container: HTMLElement, err: unknown): void {
  const message = err instanceof ApiError ? err.message : 'Kutilmagan xatolik yuz berdi.';
  container.innerHTML = `<div class="state-msg error">Xatolik: ${escapeHtml(message)}</div>`;
}

export function renderEmpty(container: HTMLElement, label: string): void {
  container.innerHTML = `<div class="empty-state">${escapeHtml(label)}</div>`;
}

export function escapeHtml(input: unknown): string {
  const str = String(input ?? '');
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export function formatDate(value: unknown): string {
  if (!value) return '—';
  const date = new Date(value as string);
  if (isNaN(date.getTime())) return String(value);
  return date.toLocaleString('uz-UZ');
}
