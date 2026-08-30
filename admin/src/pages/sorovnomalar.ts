import { api, type Poll } from '../lib/api';
import { renderLoading, renderError, renderEmpty, escapeHtml, formatDate } from '../lib/ui';

export async function renderSorovnomalar(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="page-header">
      <h1>So'rovnomalar</h1>
      <p>Barcha mahallalar bo'yicha so'rovnomalar va ovoz natijalari</p>
    </div>
    <div id="polls-body"></div>
  `;
  const body = container.querySelector<HTMLElement>('#polls-body')!;
  await load(body);
}

async function load(body: HTMLElement): Promise<void> {
  renderLoading(body);
  try {
    const list = await api.getPolls();
    if (!list.length) {
      body.innerHTML = '<div class="card"></div>';
      renderEmpty(body.querySelector('.card')!, "Hozircha so'rovnomalar mavjud emas.");
      return;
    }
    body.innerHTML = list.map((p) => renderPollCard(p)).join('');
  } catch (err) {
    body.innerHTML = '<div class="card"></div>';
    renderError(body.querySelector('.card')!, err);
  }
}

function renderPollCard(p: Poll): string {
  const isClosed = Boolean(p.closesAt && new Date(p.closesAt).getTime() < Date.now());
  const totalVotes = p.results?.totalVotes ?? 0;
  const voteCounts = p.results?.voteCounts ?? [];
  return `
    <div class="card">
      <h2>${escapeHtml(p.question)}</h2>
      <p class="hint">
        Mahalla: <span class="mono">${escapeHtml(p.mahallaId)}</span>
        &middot; Yaratilgan: ${formatDate(p.createdAt)}
        &middot; Jami ovozlar: ${escapeHtml(totalVotes)}
      </p>
      <div class="actions-cell" style="margin-bottom: 14px;">
        <span class="badge ${isClosed ? 'badge-danger' : 'badge-success'}">${isClosed ? 'Yopilgan' : 'Ochiq'}</span>
        ${p.isAnonymous ? '<span class="badge badge-pending">Anonim</span>' : ''}
        ${p.allowMultiple ? '<span class="badge badge-pending">Ko\'p tanlovli</span>' : ''}
      </div>
      ${renderOptions(p.options ?? [], voteCounts, totalVotes)}
    </div>
  `;
}

function renderOptions(options: string[], voteCounts: number[], totalVotes: number): string {
  if (!options.length) return '<p class="hint">Variantlar yo\'q.</p>';
  return `
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>Variant</th>
            <th>Ovozlar</th>
          </tr>
        </thead>
        <tbody>
          ${options
            .map((opt, i) => {
              const count = voteCounts[i] ?? 0;
              const pct = totalVotes > 0 ? Math.round((count / totalVotes) * 100) : 0;
              return `
                <tr>
                  <td>${escapeHtml(opt)}</td>
                  <td>${count} ta ovoz (${pct}%)</td>
                </tr>
              `;
            })
            .join('')}
        </tbody>
      </table>
    </div>
  `;
}
