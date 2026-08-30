import { api, type AuditLogEntry } from '../lib/api';
import { renderLoading, renderError, renderEmpty, formatDate, escapeHtml } from '../lib/ui';

export async function renderAuditLog(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="page-header">
      <h1>Harakatlar tarixi</h1>
      <p>Administratorlar tomonidan bajarilgan so'nggi harakatlar</p>
    </div>
    <div class="card" id="audit-log-body"></div>
  `;
  const body = container.querySelector<HTMLElement>('#audit-log-body')!;
  renderLoading(body);

  try {
    const entries = await api.getAuditLog(50);
    if (!entries.length) {
      renderEmpty(body, 'Hozircha harakatlar qayd etilmagan.');
      return;
    }
    const sorted = [...entries].sort(
      (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
    );
    body.innerHTML = `
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Vaqt</th>
              <th>Foydalanuvchi</th>
              <th>Harakat</th>
              <th>Tafsilotlar</th>
            </tr>
          </thead>
          <tbody>
            ${sorted.map((e) => renderRow(e)).join('')}
          </tbody>
        </table>
      </div>
    `;
  } catch (err) {
    renderError(body, err);
  }
}

function renderRow(entry: AuditLogEntry): string {
  return `
    <tr>
      <td>${formatDate(entry.timestamp)}</td>
      <td class="mono">${escapeHtml(entry.actorUid)}</td>
      <td>${escapeHtml(entry.action)}</td>
      <td>${formatDetails(entry.details)}</td>
    </tr>
  `;
}

function formatDetails(details: AuditLogEntry['details']): string {
  if (details == null) return '—';
  if (typeof details === 'string') return escapeHtml(details);
  const entries = Object.entries(details);
  if (!entries.length) return '—';
  const summary = entries
    .map(([key, value]) => `${escapeHtml(key)}: ${escapeHtml(formatValue(value))}`)
    .join(', ');
  return `<span class="mono">${summary}</span>`;
}

function formatValue(value: unknown): string {
  if (value == null) return '—';
  if (typeof value === 'object') return JSON.stringify(value);
  return String(value);
}
