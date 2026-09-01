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

// Open models like Llama tend to be over-eager: asked one narrow
// question, they'll volunteer a wall of loosely-related information
// "just in case" (e.g. answering "who owns this app" and listing every
// feature when only asked "how do I use the app"). This line exists
// specifically to curb that — without it, both `withAppContext`'s facts
// and `actionBlockHintFor`'s premium capability kept leaking into
// completely unrelated answers as unsolicited asides.
const FOCUS_HINT_UZ =
  "Faqat foydalanuvchi ANIQ so'ragan savolga javob ber — javobingga " +
  "so'ralmagan qo'shimcha mavzular, faktlar yoki takliflarni o'zingdan " +
  "qo'shib yubormaslikka harakat qil.";
const FOCUS_HINT_RU =
  'Отвечай ТОЛЬКО на то, о чём именно спросил пользователь — не добавляй ' +
  'от себя посторонние темы, факты или предложения, о которых не спрашивали.';
const FOCUS_HINT_EN =
  "Answer ONLY what the user actually asked — don't volunteer unrelated " +
  'topics, facts, or suggestions they didn\'t ask about.';

const SYSTEM_INSTRUCTIONS = {
  uz:
    "Sen \"Mening Mahallam\" ilovasining AI yordamchisisan — bu O'zbekistondagi " +
    "mahalla jamoasi ilovasi (e'lonlar, tadbirlar, murojaatlar, so'rovnomalar, " +
    "qo'shnilar bilan aloqa, mahalliy xizmatlar kabi bo'limlari bor). Foydalanuvchilarga " +
    `aniq va foydali javob ber. ${FOCUS_HINT_UZ} ${FORMATTING_HINT_UZ} Javoblaringni o'zbek tilida yoz.`,
  ru:
    "Ты — ИИ-помощник приложения \"Mening Mahallam\" — это приложение для " +
    "махаллинского (соседского) сообщества в Узбекистане (объявления, события, " +
    `обращения, опросы, общение с соседями, местные услуги). ${FOCUS_HINT_RU} ${FORMATTING_HINT_RU} ` +
    'Отвечай на русском языке.',
  en:
    'You are the AI assistant for "Mening Mahallam" — a neighborhood community app ' +
    'for Uzbekistan (announcements, events, resident requests, polls, neighbor chat, ' +
    `local services). ${FOCUS_HINT_EN} ${FORMATTING_HINT_EN} Answer in English.`,
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
  "— oddiy savol-javoblarda hech qachon qo'shma.\n\n" +
  "Bulardan tashqari, yana UCHTA sodda imkoniyat bor (premium " +
  "foydalanuvchilar uchun) — bularda qo'shimcha tafsilot yig'ish shart " +
  "emas, foydalanuvchining niyati aniq bo'lgan zahoti blokni darhol qo'sh:\n" +
  "1) Foydalanuvchi ilova haqida fikr-mulohaza/shikoyat qoldirmoqchi " +
  "bo'lsa yoki aniq rais/superadmin bilan to'g'ridan-to'g'ri bog'lanmoqchi " +
  "bo'lsa (aniq bir mahalla murojaatiga bog'liq bo'lmagan holda): " +
  "```mahallam-action\n{\"action\":\"open_feedback\"}\n```\n" +
  "2) Foydalanuvchi ilovadagi mavjud mahalliy xizmatlarni ko'rmoqchi/" +
  "bilmoqchi bo'lsa: ```mahallam-action\n{\"action\":\"open_services\"}\n```\n" +
  "3) Foydalanuvchi aniq ravishda yordam/qo'llab-quvvatlash bo'limiga " +
  "yo'naltirilishni yoki ilova qanday ishlashi haqida umumiy yordam " +
  "resursini so'rasa (bu shunchaki savolga sen o'zing matn bilan javob " +
  "bera oladigan holatlardan farqli — faqat aniq yordam bo'limiga " +
  "yo'naltirishni so'raganda ishlat): ```mahallam-action\n" +
  "{\"action\":\"open_help\"}\n```\n" +
  "Bu uchta blokni ham FAQAT mos niyat ANIQ ifodalanganda qo'sh, hech " +
  "qachon o'zingdan taklif qilmasdan. Barcha bu imkoniyatlar (murojaat " +
  "yozish ham) haqida foydalanuvchi o'zi so'ramaguncha, boshqa mavzudagi " +
  "javoblaringda HECH QACHON eslatib o'tirma yoki taklif qilma — bular " +
  "\"qo'shimcha eslatma\" emas, faqat aniq so'ralgandagina ishlatiladigan " +
  "maxfiy imkoniyatlar.";
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
  'обращение и достаточно деталей собрано — никогда в обычных вопросах-ответах.\n\n' +
  'Кроме этого, есть ещё ТРИ простые возможности (тоже только для ' +
  'премиум-пользователей) — для них не нужно собирать детали, добавляй ' +
  'блок сразу, как только намерение пользователя стало явным:\n' +
  '1) Пользователь хочет оставить отзыв/жалобу о самом приложении или ' +
  'напрямую связаться с раисом/суперадмином (не по конкретному ' +
  'обращению в махаллю): ```mahallam-action\n{"action":"open_feedback"}\n```\n' +
  '2) Пользователь хочет посмотреть/узнать доступные местные услуги в ' +
  'приложении: ```mahallam-action\n{"action":"open_services"}\n```\n' +
  '3) Пользователь явно просит направить его в раздел помощи/поддержки ' +
  'или спрашивает, как в целом работает приложение (это отличается от ' +
  'случаев, когда ты сам можешь просто ответить текстом — используй ' +
  'только когда явно просят направить в раздел помощи): ' +
  '```mahallam-action\n{"action":"open_help"}\n```\n' +
  'Добавляй эти три блока ТОЛЬКО при явном намерении, никогда не ' +
  'предлагая их сама. Никогда не упоминай и не предлагай ни одну из этих ' +
  'возможностей (включая составление обращения), пока пользователь сам ' +
  'не попросит об этом.';
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
  "request and you've gathered enough detail — never during normal Q&A.\n\n" +
  "There are also THREE simple capabilities (also premium users only) " +
  "that need no extra detail gathering — add the block as soon as the " +
  "user's intent is unambiguous:\n" +
  "1) The user wants to leave feedback/a complaint about the app itself, " +
  "or wants to contact the rais/superadmin directly about something not " +
  "tied to a specific neighborhood request: ```mahallam-action\n" +
  '{"action":"open_feedback"}\n```\n' +
  "2) The user wants to see/browse the local services available in the " +
  "app: ```mahallam-action\n{\"action\":\"open_services\"}\n```\n" +
  "3) The user explicitly asks to be directed to a help/support section, " +
  "or asks in general how the app works (different from cases you can " +
  "just answer yourself in text — only use this when they specifically " +
  "ask to be pointed to help/support): ```mahallam-action\n" +
  "{\"action\":\"open_help\"}\n```\n" +
  "Only add these three blocks when the intent is explicit and " +
  "unambiguous — never suggest them yourself. Never mention or offer any " +
  "of these capabilities (including drafting a request) unless the user " +
  "brings it up first.";

// Free-tier equivalent of ACTION_BLOCK_HINT_* above: non-premium users get
// exactly one action capability instead — an upsell nudge towards
// Premium, triggered only when they show clear interest in upgrading (or
// ask how to remove a limit they've just hit).
const FREE_ACTION_HINT_UZ =
  "Senda bitta maxsus imkoniyat bor: agar foydalanuvchi premium obunaga " +
  "aniq qiziqish bildirsa, premium nima berishini so'rasa yoki " +
  "cheklovlarni (masalan kunlik AI so'rov limitini) qanday olib " +
  "tashlashni so'rasa, oddiy javobingdan KEYIN, alohida qatorda aynan " +
  "quyidagi formatda blok qo'sh (boshqa hech narsa qo'shmasdan, faqat " +
  "to'g'ri JSON):\n```mahallam-action\n{\"action\":\"open_premium\"}\n```\n" +
  "Bu blokni FAQAT shunday aniq qiziqish/savol bo'lganda qo'sh — boshqa " +
  "mavzudagi javoblaringda premium haqida o'zingdan HECH QACHON eslatib " +
  "o'tirma yoki taklif qilma.";
const FREE_ACTION_HINT_RU =
  'У тебя есть одна особая возможность: если пользователь проявляет явный ' +
  'интерес к премиум-подписке, спрашивает, что даёт премиум, или как ' +
  'снять ограничения (например, дневной лимит запросов к ИИ), добавь ' +
  'ПОСЛЕ обычного ответа отдельной строкой блок ровно в таком формате ' +
  '(больше ничего не добавляя, только корректный JSON):\n' +
  '```mahallam-action\n{"action":"open_premium"}\n```\n' +
  'Добавляй этот блок ТОЛЬКО при таком явном интересе/вопросе — никогда ' +
  'не упоминай и не предлагай премиум сама в ответах на другие темы.';
const FREE_ACTION_HINT_EN =
  "You have one special capability: if the user shows clear interest in " +
  "the premium subscription, asks what premium offers, or asks how to " +
  "remove a limit (e.g. they hit the daily AI request limit and ask how " +
  "to get more), add a block AFTER your normal reply, on its own line, " +
  "in exactly this format (nothing else added, valid JSON only):\n" +
  "```mahallam-action\n{\"action\":\"open_premium\"}\n```\n" +
  "Only add this block on such explicit interest/questions — never " +
  "mention or suggest premium yourself in answers about unrelated topics.";

function actionBlockHintFor(locale) {
  const key = ['uz', 'ru', 'en'].includes(locale) ? locale : 'uz';
  return { uz: ACTION_BLOCK_HINT_UZ, ru: ACTION_BLOCK_HINT_RU, en: ACTION_BLOCK_HINT_EN }[key];
}

function freeActionHintFor(locale) {
  const key = ['uz', 'ru', 'en'].includes(locale) ? locale : 'uz';
  return { uz: FREE_ACTION_HINT_UZ, ru: FREE_ACTION_HINT_RU, en: FREE_ACTION_HINT_EN }[key];
}

// Client-side rendering note: the Flutter app's chat sidebar
// (`AssistantSidebar` in `lib/features/assistant/presentation/
// assistant_sidebar.dart`) shows each saved chat's title in the list —
// without this block, every chat would just show its raw first message
// truncated to 60 chars (see `AssistantChatRepository.createChat`),
// which is fine but a real short topic title reads much better. This is
// basic UX, not a paid perk, so it goes to every user (premium or not) —
// unlike ACTION_BLOCK_HINT_*/FREE_ACTION_HINT_* above.
const TITLE_BLOCK_HINT_UZ =
  "Bundan tashqari, agar bu suhbatdagi ENG BIRINCHI xabar bo'lsa, oddiy " +
  "javobingdan (va agar yuqoridagi maxsus blok qo'shgan bo'lsang, undan " +
  "ham) KEYIN, alohida qatorda aynan quyidagi formatda yana bitta blok " +
  "qo'sh (boshqa hech narsa qo'shmasdan, faqat to'g'ri JSON) — suhbat " +
  "mavzusini 3-6 so'zda ifodalovchi qisqa sarlavha bilan, xabar qaysi " +
  "tilda yozilgan bo'lsa o'sha tilda, qo'shtirnoq yoki boshqa " +
  "belgilarsiz:\n```mahallam-title\n{\"title\":\"...\"}\n```\n" +
  "Bu blokni FAQAT suhbatning eng birinchi xabariga javob berayotganda " +
  "qo'sh — suhbat davomidagi keyingi xabarlarda hech qachon qo'shma.";
const TITLE_BLOCK_HINT_RU =
  'Кроме того, если это САМОЕ ПЕРВОЕ сообщение в этом чате, добавь ПОСЛЕ ' +
  'обычного ответа (и после специального блока выше, если ты его ' +
  'добавила) ещё один блок отдельной строкой ровно в таком формате ' +
  '(больше ничего не добавляя, только корректный JSON) — с коротким ' +
  'заголовком из 3-6 слов, отражающим тему разговора, на том же языке, ' +
  'на котором написано сообщение, без кавычек и прочих знаков:\n' +
  '```mahallam-title\n{"title":"..."}\n```\n' +
  'Добавляй этот блок ТОЛЬКО отвечая на самое первое сообщение чата — ' +
  'никогда в последующих сообщениях этого же разговора.';
const TITLE_BLOCK_HINT_EN =
  "Also, if this is the VERY FIRST message in this chat, AFTER your " +
  "normal reply (and after the special block above, if you added one), " +
  "add one more block on its own line in exactly this format (nothing " +
  "else added, valid JSON only) — with a short 3-6 word title capturing " +
  "the topic of the conversation, in the same language the message was " +
  "written in, no surrounding quotes or punctuation:\n" +
  "```mahallam-title\n{\"title\":\"...\"}\n```\n" +
  "Only add this block when replying to the very first message of the " +
  "chat — never on later messages in the same conversation.";

function titleBlockHintFor(locale) {
  const key = ['uz', 'ru', 'en'].includes(locale) ? locale : 'uz';
  return { uz: TITLE_BLOCK_HINT_UZ, ru: TITLE_BLOCK_HINT_RU, en: TITLE_BLOCK_HINT_EN }[key];
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
    `Ilovaning egasi/asoschisi: ${ownerName}. FAQAT kimdir aniq "ilova egasi ` +
      `kim", "buni kim yaratgan" kabi savol bersa, aynan shu ismni ayt.`,
    mahallaNames
      ? `Ilovada ro'yxatdan o'tgan mahallalar soni: ${mahallaCount} ta, ` +
        `nomlari: ${mahallaNames.join(', ')}. FAQAT kimdir aniq "nechta mahalla ` +
        `bor" yoki ro'yxatini so'rasa, shu ma'lumotdan foydalan.`
      : `Ilovada ro'yxatdan o'tgan mahallalar soni: ${mahallaCount} ta (soni ` +
        `juda ko'p bo'lgani uchun ro'yxati berilmagan). FAQAT kimdir aniq ` +
        `"nechta mahalla bor" deb so'rasa shu sonni ayt.`,
  ].join('\n');
  return (
    `${baseInstruction}\n\n` +
    `MUHIM: quyida faqat KERAK BO'LGANDA ishlatadigan qo'shimcha ma'lumotlar ` +
    `berilgan — bularni faqat aynan mos savol berilganda ishlat, boshqa ` +
    `har qanday javobingda bu ma'lumotlarni o'zingdan qo'shib, tilga olib ` +
    `o'tirma:\n${facts}`
  );
}

/**
 * Converts our `{role: 'user'|'model', text}` history + the new message
 * into Workers AI's OpenAI-style `messages` array (`role: 'system' |
 * 'user' | 'assistant'`).
 */
function buildMessages(message, history, locale, appContext, isPremium, isFirstMessage) {
  const trimmedHistory = Array.isArray(history) ? history.slice(-MAX_HISTORY_TURNS) : [];
  const messages = trimmedHistory
    .filter((turn) => turn && (turn.role === 'user' || turn.role === 'model') && typeof turn.text === 'string')
    .map((turn) => ({
      role: turn.role === 'model' ? 'assistant' : 'user',
      content: turn.text,
    }));

  let systemContent = withAppContext(systemInstructionFor(locale), appContext);
  // Every user gets exactly one of the two hint sets, never both, never
  // neither: premium users get the full action-block capability set
  // (create_request + open_feedback/open_services/open_help), free
  // users get only the open_premium upsell nudge.
  systemContent = `${systemContent}\n\n${isPremium ? actionBlockHintFor(locale) : freeActionHintFor(locale)}`;
  // Title generation is basic UX, not a paid perk — unlike the hint
  // above, every user gets it, but only on the first exchange of a
  // brand-new chat (there's no point re-titling an existing chat).
  if (isFirstMessage) {
    systemContent = `${systemContent}\n\n${titleBlockHintFor(locale)}`;
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
export async function generateReply(env, { message, history, locale, appContext, isPremium, isFirstMessage }) {
  if (!env.AI) {
    throw new HttpError(500, 'AI assistant is not configured (missing AI binding)');
  }

  const model = env.WORKERS_AI_MODEL || '@cf/meta/llama-3.3-70b-instruct-fp8-fast';
  const messages = buildMessages(message, history, locale, appContext, isPremium, isFirstMessage);

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
