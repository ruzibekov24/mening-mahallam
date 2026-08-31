// Mening Mahallam — AI chat-assistant Worker.
//
// Pure REST API (single route). Any signed-in Firebase user may call
// `POST /chat` (no role check, unlike admin-worker's superAdmin gate) —
// see lib/auth.js. Chat completion runs on Cloudflare Workers AI (the
// `env.AI` binding below) — no external API key to provision or leak-
// proof, and no per-model daily request cap shared across the whole
// project the way Gemini's free tier was (see lib/workersAi.js for the
// full story on why this replaced the earlier Gemini integration).

import { requireAuthedUser } from './lib/auth.js';
import { corsHeaders, jsonResponse, handleOptions, HttpError } from './lib/http.js';
import { enforceRateLimit } from './lib/rateLimit.js';
import { generateReply } from './lib/workersAi.js';
import { getDoc, listCollection } from './lib/firestore.js';

// Real, live facts about the app/deployment for the AI to ground its
// answers in — without this, the model has no idea it's "Mening
// Mahallam" beyond the static system instruction text, and hallucinates
// generic answers ("rasmiy tashkilotlar bilan bog'laning") for questions
// like "who owns this app" or "how many mahallas are registered".
// Cached per-isolate since `mahallas` rarely changes and we don't want a
// Firestore list call on every single chat message.
const APP_OWNER_NAME = 'Ilyos Ruzibekov';
// Above this count, naming every mahalla would bloat the prompt (and
// eventually blow past Gemini's context window) for no real benefit —
// switch to just reporting the total.
const MAX_MAHALLA_NAMES_IN_PROMPT = 40;

let appContextCache = { value: null, fetchedAt: 0 };
const APP_CONTEXT_CACHE_TTL_MS = 5 * 60 * 1000;

async function resolveAppContext(env) {
  const now = Date.now();
  if (appContextCache.value && now - appContextCache.fetchedAt < APP_CONTEXT_CACHE_TTL_MS) {
    return appContextCache.value;
  }
  let mahallas = [];
  try {
    mahallas = await listCollection(env, 'mahallas');
  } catch (err) {
    console.error('assistant app-context: mahallas lookup failed:', err);
  }
  const names = mahallas.map((m) => m.name).filter((n) => typeof n === 'string' && n);
  const context = {
    ownerName: APP_OWNER_NAME,
    mahallaCount: mahallas.length,
    mahallaNames: names.length <= MAX_MAHALLA_NAMES_IN_PROMPT ? names : null,
  };
  appContextCache = { value: context, fetchedAt: now };
  return context;
}

export default {
  async fetch(request, env, ctx) {
    const { pathname } = new URL(request.url);

    if (request.method === 'OPTIONS') return handleOptions(env);

    if (pathname === '/health') {
      return jsonResponse({ ok: true }, 200, env);
    }

    try {
      if (request.method === 'POST' && pathname === '/chat') {
        return await handleChat(request, env);
      }
      throw new HttpError(404, 'Not found');
    } catch (err) {
      if (err instanceof HttpError) {
        return jsonResponse({ error: err.message }, err.status, env);
      }
      // Unexpected error — never leak stack traces or internals.
      console.error(err);
      return jsonResponse({ error: 'Internal error' }, 500, env);
    }
  },
};

/**
 * POST /chat  { message: string, history?: Array<{role, text}>, locale?: string }
 * -> { reply: string }
 */
async function handleChat(request, env) {
  // Any signed-in user, no role check — this is the one difference from
  // admin-worker's `requireSuperAdmin` pattern.
  const uid = await requireAuthedUser(request);

  let isPremium = false;
  try {
    const userDoc = await getDoc(env, 'users', uid);
    const premiumUntil = userDoc?.premiumUntil ? new Date(userDoc.premiumUntil) : null;
    isPremium = !!premiumUntil && premiumUntil.getTime() > Date.now();
  } catch (err) {
    // Premium lookup failing shouldn't block chat entirely — just treat
    // as non-premium (the safe/conservative default) for this request.
    console.error('assistant: premium lookup failed:', err);
  }

  await enforceRateLimit(env, uid, isPremium);

  const body = await safeJson(request);
  if (!body || typeof body.message !== 'string' || !body.message.trim()) {
    throw new HttpError(400, 'message is required');
  }
  if (body.history !== undefined && !Array.isArray(body.history)) {
    throw new HttpError(400, 'history must be an array if provided');
  }
  if (body.locale !== undefined && typeof body.locale !== 'string') {
    throw new HttpError(400, 'locale must be a string if provided');
  }

  const appContext = await resolveAppContext(env);

  const reply = await generateReply(env, {
    message: body.message.trim(),
    history: body.history,
    locale: body.locale,
    appContext,
    // isPremium gates the "draft a murojaat for me" action-block
    // capability (see lib/workersAi.js) — kept as its own parameter
    // rather than folded into `appContext`, since appContext is cached
    // and shared across every user's request, while premium status is
    // per-request/per-uid.
    isPremium,
  });

  return jsonResponse({ reply }, 200, env);
}

async function safeJson(request) {
  try {
    return await request.json();
  } catch {
    return null;
  }
}
