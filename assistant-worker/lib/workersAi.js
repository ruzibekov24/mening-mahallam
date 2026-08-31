// Chat completion via Cloudflare Workers AI — replaces the earlier
// Gemini-based implementation (see git history for `lib/gemini.js`).
//
// Why the switch: Gemini's free tier quota (`generate_content_free_tier_
// requests`) is capped **per Google Cloud project per model per day**,
// not per API key — so rotating the key never helps once that project-
// wide daily cap is hit, and the smaller/newer Gemini models have very
// low free caps (as low as 20 requests/day for the whole app). Workers
// AI runs on the same Cloudflare account this Worker is already
// deployed to: no external API key to provision or leak-proof, and a
// daily free Neuron allowance (rather than a fixed per-model request
// count) shared across every model available on the platform.
//
// Trade-off (explicitly accepted): the open models available here
// (Llama, in this case) are less capable than Gemini for nuanced or
// long-context questions — the smallest instruct models (8B) were tried
// first but proved too weak (generic, un-grounded answers even with the
// system-instruction context below), so `WORKERS_AI_MODEL` currently
// points at Llama 3.3 70B instead — noticeably better answer quality,
// at the cost of burning through the shared free daily Neuron allowance
// faster per message than a small model would.

import { HttpError } from './http.js';

/** How many of the most recent history turns to forward — bounds
 * context length (and therefore Neuron cost) per request, regardless of
 * how long the client's local conversation has grown. */
const MAX_HISTORY_TURNS = 10;

// Client-side rendering note: the Flutter app's chat bubble
// (`_MarkdownLiteText` in `lib/features/assistant/presentation/
// assistant_screen.dart`) understands `**bold**` and `* `/`1. ` list
// markers and renders them properly — so it's safe (and, per user
// feedback, expected) to actually use that formatting rather than
// writing plain unformatted paragraphs.
const FORMATTING_HINT_UZ =
  "Javoblaring yetarlicha batafsil va tushunarli bo'lsin — juda qisqa, " +
  "bir gapli javoblardan qoching. Kerak bo'lsa **qalin matn** bilan muhim " +
  "so'zlarni ajrat, va ro'yxat kerak bo'lsa \"1. \", \"2. \" yoki \"* \" " +
  "bilan boshlangan qatorlardan foydalan (bular ilovada to'g'ri formatlab " +
  "ko'rsatiladi).";
const FORMATTING_HINT_RU =
  'Отвечай достаточно подробно и понятно — избегай слишком коротких, ' +
  'однострочных ответов. При необходимости выделяй важные слова ' +
  '**жирным текстом**, а для списков используй строки, начинающиеся с ' +
  '"1. ", "2. " или "* " (они корректно отображаются в приложении).';
const FORMATTING_HINT_EN =
  'Answer with enough detail to be genuinely useful — avoid overly short, ' +
  'one-line answers. Use **bold text** for important words where it ' +
  'helps, and lines starting with "1. ", "2. " or "* " for lists (these ' +
  'render correctly in the app).';

const SYSTEM_INSTRUCTIONS = {
  uz:
    "Sen \"Mening Mahallam\" ilovasining AI yordamchisisan — bu O'zbekistondagi " +
    "mahalla jamoasi ilovasi (e'lonlar, tadbirlar, murojaatlar, so'rovnomalar, " +
    "qo'shnilar bilan aloqa, mahalliy xizmatlar kabi bo'limlari bor). Foydalanuvchilarga " +
    `aniq va foydali javob ber. ${FORMATTING_HINT_UZ} Javoblaringni o'zbek tilida yoz.`,
  ru:
    "Ты — ИИ-помощник приложения \"Mening Mahallam\" — это приложение для " +
    "махаллинского (соседского) сообщества в Узбекистане (объявления, события, " +
    `обращения, опросы, общение с соседями, местные услуги). ${FORMATTING_HINT_RU} ` +
    'Отвечай на русском языке.',
  en:
    'You are the AI assistant for "Mening Mahallam" — a neighborhood community app ' +
    'for Uzbekistan (announcements, events, resident requests, polls, neighbor chat, ' +
    `local services). ${FORMATTING_HINT_EN} Answer in English.`,
};

function systemInstructionFor(locale) {
  const key = ['uz', 'ru', 'en'].includes(locale) ? locale : 'uz';
  return SYSTEM_INSTRUCTIONS[key];
}

// Premium-only capability: instead of just describing how to file a
// murojaat, the assistant can draft one and hand it to the app to
// pre-fill the real "Yangi murojaat" form — the user still has to
// review and submit it themself (this Worker never creates the request
// directly; see `_MarkdownLiteText`'s sibling in `assistant_screen.dart`
// for the client-side parser that turns this fenced block into a
// "formani to'ldirish" button). Free-tier users don't get this
// instruction at all, so the model has no reason to ever emit the block
// for them — gating happens server-side, not just in the UI.
const ACTION_BLOCK_HINT_UZ =
  "Sen yana bitta maxsus (faqat premium foydalanuvchilar uchun) imkoniyatga " +
  "egasan: agar foydalanuvchi sendan uning nomidan murojaat/shikoyat/taklif " +
  "yozib berishingni so'rasa, avval suhbat orqali kerakli tafsilotlarni " +
  "(muammo aniq nima, qayerda/qachon, qanchalik shoshilinch) so'rab bil. " +
  "Yetarli ma'lumot to'planganda, oddiy javobingdan KEYIN, alohida qatorda " +
  "aynan quyidagi formatda blok qo'sh (boshqa hech narsa qo'shmasdan, " +
  "faqat to'g'ri JSON):\n" +
  "```mahallam-action\n" +
  '{"action":"create_request","title":"...","description":"...",' +
  '"type":"ommaviy yoki maxfiy","priority":"past, ortacha yoki yuqori"}\n' +
  "```\n" +
  "Bu blokni FAQAT foydalanuvchi ANIQ ravishda murojaat/shikoyat yozib " +
  "berishingni so'raganda va yetarli tafsilot to'plaganingdan keyin qo'sh " +
  "— oddiy savol-javoblarda hech qachon qo'shma.";
const ACTION_BLOCK_HINT_RU =
  'У тебя есть ещё одна особая возможность (только для премиум-' +
  'пользователей): если пользователь просит тебя составить от его имени ' +
  'обращение/жалобу/предложение, сначала уточни через диалог нужные детали ' +
  '(в чём именно проблема, где/когда, насколько срочно). Когда деталей ' +
  'достаточно, ПОСЛЕ обычного ответа добавь отдельной строкой блок ровно ' +
  'в таком формате (больше ничего не добавляя, только корректный JSON):\n' +
  '```mahallam-action\n' +
  '{"action":"create_request","title":"...","description":"...",' +
  '"type":"ommaviy или maxfiy","priority":"past, ortacha или yuqori"}\n' +
  '```\n' +
  'Добавляй этот блок ТОЛЬКО когда пользователь явно просит составить ' +
  'обращение и достаточно деталей собрано — никогда в обычных вопросах-ответах.';
const ACTION_BLOCK_HINT_EN =
  "You also have one special capability (premium users only): if the user " +
  "asks you to draft a murojaat (resident request/complaint/suggestion) on " +
  "their behalf, first ask through conversation for the needed details " +
  "(what exactly the issue is, where/when, how urgent). Once you have " +
  "enough detail, AFTER your normal reply, add a block on its own line in " +
  "exactly this format (nothing else added, valid JSON only):\n" +
  "```mahallam-action\n" +
  '{"action":"create_request","title":"...","description":"...",' +
  '"type":"ommaviy or maxfiy","priority":"past, ortacha or yuqori"}\n' +
  "```\n" +
  "Only add this block when the user explicitly asks you to draft a " +
  "request and you've gathered enough detail — never during normal Q&A.";

function actionBlockHintFor(locale) {
  const key = ['uz', 'ru', 'en'].includes(locale) ? locale : 'uz';
  return { uz: ACTION_BLOCK_HINT_UZ, ru: ACTION_BLOCK_HINT_RU, en: ACTION_BLOCK_HINT_EN }[key];
}

/**
 * Appends real, live facts about this deployment (app owner, mahalla
 * count/list) to the base system instruction — without this, the model
 * has no grounding for questions like "ilova egasi kim" or "nechta
 * mahalla bor" and invents generic non-answers instead.
 */
function withAppContext(baseInstruction, appContext) {
  if (!appContext) return baseInstruction;
  const { ownerName, mahallaCount, mahallaNames } = appContext;
  const facts = [
    `Ilovaning egasi/asoschisi: ${ownerName}. Kimdir "ilova egasi kim", ` +
      `"buni kim yaratgan" kabi savol bersa, aynan shu ismni ayt — ` +
      `"rasmiy tashkilot" yoki umumiy javob berma.`,
    mahallaNames
      ? `Hozirda ilovada ro'yxatdan o'tgan mahallalar soni: ${mahallaCount} ta. ` +
        `Ularning nomlari: ${mahallaNames.join(', ')}. Kimdir "nechta mahalla bor" ` +
        `yoki ro'yxatini so'rasa, shu ma'lumotdan foydalan.`
      : `Hozirda ilovada ro'yxatdan o'tgan mahallalar soni: ${mahallaCount} ta ` +
        `(soni juda ko'p bo'lgani uchun ro'yxati bu yerda berilmagan — kimdir ` +
        `ro'yxatini so'rasa, mahallalar sonini ayt va aniq bir mahallani ilova ` +
        `ichidagi qidiruv orqali topishni tavsiya qil).`,
  ].join('\n');
  return `${baseInstruction}\n\nQuyidagi haqiqiy ma'lumotlarga tayanib javob ber:\n${facts}`;
}

/**
 * Converts our `{role: 'user'|'model', text}` history + the new message
 * into Workers AI's OpenAI-style `messages` array (`role: 'system' |
 * 'user' | 'assistant'`).
 */
function buildMessages(message, history, locale, appContext, isPremium) {
  const trimmedHistory = Array.isArray(history) ? history.slice(-MAX_HISTORY_TURNS) : [];
  const messages = trimmedHistory
    .filter((turn) => turn && (turn.role === 'user' || turn.role === 'model') && typeof turn.text === 'string')
    .map((turn) => ({
      role: turn.role === 'model' ? 'assistant' : 'user',
      content: turn.text,
    }));

  let systemContent = withAppContext(systemInstructionFor(locale), appContext);
  if (isPremium) {
    systemContent = `${systemContent}\n\n${actionBlockHintFor(locale)}`;
  }

  return [
    { role: 'system', content: systemContent },
    ...messages,
    { role: 'user', content: message },
  ];
}

/**
 * Calls Workers AI's chat-completion `run()` with the given
 * message/history/locale/appContext and returns the reply text. Throws
 * `HttpError` on any failure.
 */
export async function generateReply(env, { message, history, locale, appContext, isPremium }) {
  if (!env.AI) {
    throw new HttpError(500, 'AI assistant is not configured (missing AI binding)');
  }

  const model = env.WORKERS_AI_MODEL || '@cf/meta/llama-3.3-70b-instruct-fp8-fast';
  const messages = buildMessages(message, history, locale, appContext, isPremium);

  let result;
  try {
    result = await env.AI.run(model, {
      messages,
      max_tokens: 1024,
    });
  } catch (err) {
    console.error('Workers AI request failed:', err);
    throw new HttpError(502, "AI xizmatiga ulanib bo'lmadi. Birozdan so'ng qayta urinib ko'ring.");
  }

  const reply = (result?.response || '').trim();
  if (!reply) {
    console.error('Workers AI returned no usable text:', JSON.stringify(result).slice(0, 500));
    throw new HttpError(502, 'AI javob bera olmadi. Boshqacha savol bilan urinib ko\'ring.');
  }

  return reply;
}
