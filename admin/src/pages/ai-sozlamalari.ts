import { api, ApiError } from '../lib/api';
import { renderLoading, renderError } from '../lib/ui';

export async function renderAiSozlamalari(container: HTMLElement): Promise<void> {
  container.innerHTML = `
    <div class="page-header">
      <h1>AI sozlamalari</h1>
      <p>AI Yordamchi (Gemini) API kalitini boshqarish</p>
    </div>
    <div class="card" id="ai-config-body"></div>
  `;
  const body = container.querySelector<HTMLElement>('#ai-config-body')!;
  await load(body);
}

async function load(body: HTMLElement): Promise<void> {
  renderLoading(body);
  try {
    const config = await api.getAssistantConfig();
    body.innerHTML = `
      <p class="fineprint">
        Gemini kalitining bepul kunlik kvotasi tugab qolsa, shu yerdan
        yangi kalit qo'yib qo'ysangiz bo'ldi — mobil ilovaga yangi
        versiya chiqarish shart emas, o'zgarish bir necha daqiqada
        kuchga kiradi.
      </p>
      <div class="field">
        <label>Joriy holat</label>
        <p>${
          config.hasKey
            ? `Kalit o'rnatilgan (${config.geminiApiKeyMasked})`
            : "Kalit o'rnatilmagan — assistant-worker'ning zaxira siridan foydalanilmoqda"
        }</p>
      </div>
      <div class="field">
        <label for="gemini-key-input">Yangi Gemini API kalit</label>
        <input type="password" id="gemini-key-input" placeholder="AIza..." autocomplete="off" />
      </div>
      <button class="btn btn-solid" id="save-key-btn">Saqlash</button>
      <p class="error-banner" id="ai-config-error" style="display:none"></p>
    `;
    const input = body.querySelector<HTMLInputElement>('#gemini-key-input')!;
    const saveBtn = body.querySelector<HTMLButtonElement>('#save-key-btn')!;
    const errorEl = body.querySelector<HTMLElement>('#ai-config-error')!;
    saveBtn.addEventListener('click', async () => {
      const value = input.value.trim();
      if (!value) return;
      saveBtn.disabled = true;
      saveBtn.innerHTML = '<span class="spinner"></span>';
      errorEl.style.display = 'none';
      try {
        await api.setAssistantGeminiKey(value);
        await load(body);
      } catch (err) {
        errorEl.textContent =
          err instanceof ApiError ? err.message : "Saqlab bo'lmadi.";
        errorEl.style.display = 'block';
        saveBtn.disabled = false;
        saveBtn.textContent = 'Saqlash';
      }
    });
  } catch (err) {
    renderError(body, err);
  }
}
