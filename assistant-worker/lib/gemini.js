// Minimal Gemini `generateContent` REST client. No SDK — just `fetch`,
// same "no npm deps" style as the rest of this repo's Workers.

import { HttpError } from './http.js';

const GEMINI_BASE_URL = 'https://generativelanguage.googleapis.com/v1beta/models';

/** How many of the most recent history turns to forward to Gemini —
 * bounds token usage (and therefore free-quota burn) per request,
 * regardless of how long the client's local conversation has grown. */
const MAX_HISTORY_TURNS = 10;

const SYSTEM_INSTRUCTIONS = {
  uz:
    "Sen \"Mening Mahallam\" ilovasining AI yordamchisisan — bu O'zbekistondagi " +
    "mahalla jamoasi ilovasi (e'lonlar, tadbirlar, murojaatlar, so'rovnomalar, " +
    "qo'shnilar bilan aloqa, mahalliy xizmatlar kabi bo'limlari bor). Foydalanuvchilarga " +
    "qisqa, aniq va foydali javob ber. Javoblaringni o'zbek tilida yoz.",
  ru:
    "Ты — ИИ-помощник приложения \"Mening Mahallam\" — это приложение для " +
    "махаллинского (соседского) сообщества в Узбекистане (объявления, события, " +
    "обращения, опросы, общение с соседями, местные услуги). Отвечай кратко, " +
    "по делу и полезно. Отвечай на русском языке.",
  en:
    'You are the AI assistant for "Mening Mahallam" — a neighborhood community app ' +
    'for Uzbekistan (announcements, events, resident requests, polls, neighbor chat, ' +
    'local services). Answer concisely and helpfully, in English.',
};

function systemInstructionFor(locale) {
  const key = ['uz', 'ru', 'en'].includes(locale) ? locale : 'uz';
  return SYSTEM_INSTRUCTIONS[key];
}

/**
 * Converts our `{role, text}` history + the new message into Gemini's
 * `contents` array shape. Gemini uses `role: 'user' | 'model'`, which
 * conveniently matches the contract's own role names.
 */
function buildContents(message, history) {
  const trimmedHistory = Array.isArray(history) ? history.slice(-MAX_HISTORY_TURNS) : [];
  const contents = trimmedHistory
    .filter((turn) => turn && (turn.role === 'user' || turn.role === 'model') && typeof turn.text === 'string')
    .map((turn) => ({ role: turn.role, parts: [{ text: turn.text }] }));

  contents.push({ role: 'user', parts: [{ text: message }] });
  return contents;
}

/**
 * Calls Gemini's `generateContent` with the given message/history/locale
 * and returns the reply text. Throws `HttpError` on any failure — never
 * leaks the API key or raw upstream error bodies to the client.
 */
export async function generateReply(env, { message, history, locale }) {
  if (!env.GEMINI_API_KEY) {
    throw new HttpError(500, 'AI assistant is not configured (missing API key)');
  }

  const model = env.GEMINI_MODEL || 'gemini-3.6-flash';
  const url = `${GEMINI_BASE_URL}/${model}:generateContent?key=${env.GEMINI_API_KEY}`;

  const body = {
    contents: buildContents(message, history),
    systemInstruction: {
      role: 'system',
      parts: [{ text: systemInstructionFor(locale) }],
    },
    generationConfig: {
      temperature: 0.7,
      maxOutputTokens: 1024,
    },
  };

  let res;
  try {
    res = await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(body),
    });
  } catch (err) {
    console.error('Gemini request failed:', err);
    throw new HttpError(502, "AI xizmatiga ulanib bo'lmadi. Birozdan so'ng qayta urinib ko'ring.");
  }

  if (!res.ok) {
    const errText = await res.text().catch(() => '');
    console.error('Gemini API error:', res.status, errText);
    if (res.status === 429) {
      throw new HttpError(429, "AI xizmati hozircha band. Birozdan so'ng qayta urinib ko'ring.");
    }
    throw new HttpError(502, "AI javob bera olmadi. Birozdan so'ng qayta urinib ko'ring.");
  }

  const data = await res.json();
  const reply = data?.candidates?.[0]?.content?.parts?.map((p) => p.text || '').join('') || '';

  if (!reply) {
    // e.g. blocked by safety filters (finishReason: SAFETY) — data.candidates
    // may exist with no usable text, or be empty entirely.
    console.error('Gemini returned no usable text:', JSON.stringify(data).slice(0, 500));
    throw new HttpError(502, 'AI javob bera olmadi. Boshqacha savol bilan urinib ko\'ring.');
  }

  return reply;
}
