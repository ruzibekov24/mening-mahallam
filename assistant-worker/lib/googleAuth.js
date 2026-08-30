// Obtains a Google OAuth2 access token for our service account via the
// JWT-bearer grant (RFC 7523 / Google's "server to server" flow), so we
// can call the Firestore REST API with proper credentials. See:
// https://developers.google.com/identity/protocols/oauth2/service-account#httprest

import { signJwt } from './jwt.js';

const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const FIRESTORE_SCOPE = 'https://www.googleapis.com/auth/datastore';

// Module-level cache of the current access token, keyed by nothing (this
// Worker only ever authenticates as one service account). Reused across
// requests within the same isolate to avoid re-minting a token — and
// paying the extra round trip to Google — on every single API call.
let tokenCache = { accessToken: null, expiresAt: 0 };

/**
 * Returns a valid Google OAuth2 access token, minting a fresh one via the
 * service-account JWT-bearer grant if the cached one is missing/expiring.
 */
export async function getAccessToken(env) {
  const now = Date.now();
  // Refresh a little early (60s slack) to avoid a token expiring mid-flight.
  if (tokenCache.accessToken && tokenCache.expiresAt > now + 60_000) {
    return tokenCache.accessToken;
  }

  const clientEmail = env.FIREBASE_CLIENT_EMAIL;
  const privateKey = env.FIREBASE_PRIVATE_KEY;
  if (!clientEmail || !privateKey) {
    throw new Error('Service account credentials are not configured');
  }

  const nowSeconds = Math.floor(now / 1000);
  const assertion = await signJwt(
    {
      iss: clientEmail,
      scope: FIRESTORE_SCOPE,
      aud: TOKEN_URL,
      iat: nowSeconds,
      exp: nowSeconds + 3600,
    },
    privateKey,
  );

  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  if (!res.ok) {
    // Don't leak the response body (may echo back parts of the request) —
    // log status only.
    throw new Error(`Google token exchange failed: ${res.status}`);
  }

  const data = await res.json();
  tokenCache = {
    accessToken: data.access_token,
    expiresAt: now + (data.expires_in || 3600) * 1000,
  };
  return tokenCache.accessToken;
}
