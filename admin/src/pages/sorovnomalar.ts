import { api, type Poll, ApiError } from '../lib/api';
import { renderLoading, renderError, renderEmpty, escapeHtml, formatDate } from '../lib/ui';
import { populateMahallaSelect } from '../lib/mahallaSelect';

let editingPoll: Poll | null = null;

export async function renderSorovnomalar(container: HTMLElement): Promise<void> {
  editingPoll = null;
  container.innerHTML = `
    <div class="page-header">
      <h1>So'rovnomalar</h1>
      <p>Barcha mahallalar bo'yicha so'rovnomalar va ovoz natijalari</p>
    </div>
    <div class="card" id="poll-form-card"></div>
    <div id="polls-body"></div>
  `;
  const formCard = container.querySelector<HTMLElement>('#poll-form-card')!;
  const body = container.querySelector<HTMLElement>('#polls-body')!;
  renderForm(formCard, body);
  await load(body, formCard);
}

function renderForm(formCard: HTMLElement, body: HTMLElement): void {
  const editing = editingPoll;
  const options = editing?.options && editing.options.length ? editing.options : ['', ''];
  formCard.innerHTML = `
    <h2 id="poll-form-title">${editing ? "So'rovnomani tahrirlash" : "Yangi so'rovnoma"}</h2>
    <form id="poll-form">
      <div class="field">
        <label for="poll-mahallaId">Mahalla</label>
        <select id="poll-mahallaId" name="mahallaId" required></select>
      </div>
      <div class="field">
        <label for="poll-question">Savol</label>
        <input type="text" id="poll-question" name="question" required />
      </div>
      <div class="field">
        <label>Variantlar</label>
        <div id="poll-options"></div>
        <button type="button" class="btn btn-ghost btn-sm" id="poll-add-option">+ Variant qo'shish</button>
      </div>
      <div class="field" style="display:flex; gap: 20px; align-items:center;">
        <label style="display:flex; align-items:center; gap:6px; margin:0;">
          <input type="checkbox" id="poll-allowMultiple" name="allowMultiple" style="width:auto;" />
          Ko'p tanlovga ruxsat
        </label>
        <label style="display:flex; align-items:center; gap:6px; margin:0;">
          <input type="checkbox" id="poll-isAnonymous" name="isAnonymous" style="width:auto;" />
          Anonim
        </label>
      </div>
      <div class="field narrow">
        <label for="poll-closesAt">Yopilish vaqti (ixtiyoriy)</label>
        <input type="datetime-local" id="poll-closesAt" name="closesAt" />
      </div>
      <div class="actions-cell">
        <button type="submit" class="btn" id="poll-submit">${editing ? 'Saqlash' : "Qo'shish"}</button>
        <button type="button" class="btn btn-ghost" id="poll-cancel" ${editing ? '' : 'hidden'}>Bekor qilish</button>
      </div>
    </form>
    <div id="poll-form-error"></div>
  `;

  const form = formCard.querySelector<HTMLFormElement>('#poll-form')!;
  const optionsContainer = formCard.querySelector<HTMLElement>('#poll-options')!;
  const addOptionBtn = formCard.querySelector<HTMLButtonElement>('#poll-add-option')!;
  const mahallaSelect = formCard.querySelector<HTMLSelectElement>('#poll-mahallaId')!;
  const formError = formCard.querySelector<HTMLElement>('#poll-form-error')!;
  const cancelBtn = formCard.querySelector<HTMLButtonElement>('#poll-cancel')!;

  function addOptionRow(value = ''): void {
    const row = document.createElement('div');
    row.className = 'actions-cell';
    row.style.marginBottom = '8px';
    row.innerHTML = `
      <input type="text" class="poll-option-input" value="${escapeHtml(value)}" placeholder="Variant matni" style="flex:1; padding:11px 13px; border-radius:9px; border:1px solid var(--line); background:var(--paper-raised); color:var(--ink);" />
      <button type="button" class="btn btn-ghost btn-sm poll-remove-option">O'chirish</button>
    `;
    row.querySelector<HTMLButtonElement>('.poll-remove-option')!.addEventListener('click', () => {
      if (optionsContainer.children.length > 2) {
        row.remove();
      } else {
        alert('Kamida 2 ta variant bo\'lishi kerak.');
      }
    });
    optionsContainer.appendChild(row);
  }

  options.forEach((o) => addOptionRow(o));
  addOptionBtn.addEventListener('click', () => addOptionRow());

  if (editing) {
    (form.elements.namedItem('question') as HTMLInputElement).value = editing.question;
    (form.elements.namedItem('allowMultiple') as HTMLInputElement).checked = Boolean(editing.allowMultiple);
    (form.elements.namedItem('isAnonymous') as HTMLInputElement).checked = Boolean(editing.isAnonymous);
    if (editing.closesAt) {
      (form.elements.namedItem('closesAt') as HTMLInputElement).value = toLocalInputValue(editing.closesAt);
    }
    void populateMahallaSelect(mahallaSelect, editing.mahallaId);
    mahallaSelect.disabled = true;
  } else {
    void populateMahallaSelect(mahallaSelect);
  }

  cancelBtn.addEventListener('click', () => {
    editingPoll = null;
    renderForm(formCard, body);
  });

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    formError.innerHTML = '';
    const submitBtn = formCard.querySelector<HTMLButtonElement>('#poll-submit')!;
    const mahallaId = (form.elements.namedItem('mahallaId') as HTMLSelectElement).value;
    const question = (form.elements.namedItem('question') as HTMLInputElement).value.trim();
    const optionValues = Array.from(optionsContainer.querySelectorAll<HTMLInputElement>('.poll-option-input'))
      .map((i) => i.value.trim())
      .filter((v) => v.length > 0);
    const allowMultiple = (form.elements.namedItem('allowMultiple') as HTMLInputElement).checked;
    const isAnonymous = (form.elements.namedItem('isAnonymous') as HTMLInputElement).checked;
    const closesAtRaw = (form.elements.namedItem('closesAt') as HTMLInputElement).value;
    const closesAt = closesAtRaw ? new Date(closesAtRaw).toISOString() : null;

    if (!mahallaId || !question || optionValues.length < 2) {
      formError.innerHTML = '<div class="error-banner">Mahalla, savol va kamida 2 ta variant kiritilishi kerak.</div>';
      return;
    }

    submitBtn.disabled = true;
    submitBtn.innerHTML = '<span class="spinner"></span>';
    try {
      if (editingPoll) {
        await api.updatePoll(editingPoll.mahallaId, editingPoll.id, {
          question,
          options: optionValues,
          allowMultiple,
          isAnonymous,
          closesAt,
        });
      } else {
        await api.createPoll({
          mahallaId,
          question,
          options: optionValues,
          allowMultiple,
          isAnonymous,
          closesAt,
        });
      }
      editingPoll = null;
      renderForm(formCard, body);
      await load(body, formCard);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : 'Saqlab bo\'lmadi.';
      formError.innerHTML = `<div class="error-banner">${escapeHtml(message)}</div>`;
      submitBtn.disabled = false;
      submitBtn.textContent = editingPoll ? 'Saqlash' : "Qo'shish";
    }
  });
}

function toLocalInputValue(iso: string | null | undefined): string {
  if (!iso) return '';
  const d = new Date(iso);
  if (isNaN(d.getTime())) return '';
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

async function load(body: HTMLElement, formCard: HTMLElement): Promise<void> {
  renderLoading(body);
  try {
    const list = await api.getPolls();
    if (!list.length) {
      body.innerHTML = '<div class="card"></div>';
      renderEmpty(body.querySelector('.card')!, "Hozircha so'rovnomalar mavjud emas.");
      return;
    }
    body.innerHTML = list.map((p) => renderPollCard(p)).join('');
    body.querySelectorAll<HTMLButtonElement>('[data-action="edit"]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.id!;
        const poll = list.find((p) => p.id === id);
        if (!poll) return;
        editingPoll = poll;
        renderForm(formCard, body);
        formCard.scrollIntoView({ behavior: 'smooth', block: 'start' });
      });
    });
    body.querySelectorAll<HTMLButtonElement>('[data-action="delete"]').forEach((btn) => {
      btn.addEventListener('click', () => handleDelete(btn, body, formCard));
    });
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
      <div class="header-row" style="display:flex; justify-content:space-between; align-items:flex-start; gap:16px;">
        <h2 style="margin:0;">${escapeHtml(p.question)}</h2>
        <div class="actions-cell">
          <button class="btn btn-ghost btn-sm" data-action="edit" data-id="${escapeHtml(p.id)}">Tahrirlash</button>
          <button class="btn btn-danger btn-sm" data-action="delete" data-mahalla-id="${escapeHtml(p.mahallaId)}" data-id="${escapeHtml(p.id)}">O'chirish</button>
        </div>
      </div>
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

async function handleDelete(btn: HTMLButtonElement, body: HTMLElement, formCard: HTMLElement): Promise<void> {
  const id = btn.dataset.id!;
  const mahallaId = btn.dataset.mahallaId!;
  if (!confirm("Ushbu so'rovnomani o'chirishni tasdiqlaysizmi?")) return;
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner"></span>';
  try {
    await api.deletePoll(mahallaId, id);
    await load(body, formCard);
  } catch (err) {
    const message = err instanceof ApiError ? err.message : "O'chirib bo'lmadi.";
    alert(`Xatolik: ${message}`);
    btn.disabled = false;
    btn.textContent = "O'chirish";
  }
}
