// Mening Mahallam — AI chat-assistant Worker.
//
// Pure REST API (single route). Any signed-in Firebase user may call
// `POST /chat` (no role check, unlike admin-worker's superAdmin gate) —
// see lib/auth.js. The Gemini API key never reaches the client: this
// Worker calls Google's Generative Language API server-side with a
// secret set via `wrangler secret put GEMINI_API_KEY`.

import { requireAuthedUser } from './lib/auth.js';
import { corsHeaders, jsonResponse, handleOptions, HttpError } from './lib/http.js';
import { enforceRateLimit } from './lib/rateLimit.js';
import { generateReply } from './lib/gemini.js';
import { getDoc } from './lib/firestore.js';

// Gemini API key resolution: prefer a super-admin-set key stored in
// Firestore `appConfig/assistant.geminiApiKey` (editable from the web
// admin panel — see admin-worker's `/api/assistant-config` — so the key
// can be swapped without a redeploy when the free-tier quota runs out),
// falling back to the `GEMINI_API_KEY` Worker secret if no Firestore
// override is set. Cached in-memory per isolate for a few minutes so
// every chat message doesn't cost an extra Firestore read.
let keyCache = { value: null, fetchedAt: 0 };
const KEY_CACHE_TTL_MS = 5 * 60 * 1000;

async function resolveGeminiApiKey(env) {
  const now = Date.now();
  if (keyCache.value && now - keyCache.fetchedAt < KEY_CACHE_TTL_MS) {
    return keyCache.value;
  }
  let firestoreKey = null;
  try {
    const doc = await getDoc(env, 'appConfig', 'assistant');
    firestoreKey = doc?.geminiApiKey || null;
  } catch (err) {
    // Firestore unreachable/misconfigured — fall back to the secret
    // rather than failing the whole request.
    console.error('assistant config lookup failed:', err);
  }
  const resolved = firestoreKey || env.GEMINI_API_KEY || null;
  keyCache = { value: resolved, fetchedAt: now };
  return resolved;
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

  await enforceRateLimit(env, uid);

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

  const apiKey = await resolveGeminiApiKey(env);
  if (!apiKey) {
    throw new HttpError(500, 'AI yordamchi hozircha sozlanmagan');
  }

  const reply = await generateReply(
    { ...env, GEMINI_API_KEY: apiKey },
    {
      message: body.message.trim(),
      history: body.history,
      locale: body.locale,
    },
  );

  return jsonResponse({ reply }, 200, env);
}

async function safeJson(request) {
  try {
    return await request.json();
  } catch {
    return null;
  }
}
