// Auth gate for this Worker: unlike admin-worker's `requireSuperAdmin`,
// the AI assistant is available to ANY signed-in app user — there's no
// Firestore role lookup here, just Firebase ID token verification.

import { verifyFirebaseIdToken } from './firebaseAuth.js';
import { HttpError } from './http.js';

/**
 * Verifies the `Authorization: Bearer <token>` header and returns the
 * caller's Firebase uid. Throws `HttpError(401, ...)` if the token is
 * missing/invalid/expired.
 */
export async function requireAuthedUser(request) {
  const authHeader = request.headers.get('authorization') || '';
  const match = authHeader.match(/^Bearer (.+)$/i);
  if (!match) throw new HttpError(401, 'Missing or malformed Authorization header');

  let payload;
  try {
    payload = await verifyFirebaseIdToken(match[1]);
  } catch (err) {
    throw new HttpError(401, err.message || 'Invalid token');
  }

  return payload.sub; // Firebase uid
}
