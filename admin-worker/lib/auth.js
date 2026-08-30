// Auth middleware: verifies the Firebase ID token on the request and
// checks the caller's Firestore `users/{uid}.role == 'superAdmin'`.

import { verifyFirebaseIdToken } from './firebaseAuth.js';
import { getDoc } from './firestore.js';
import { HttpError } from './http.js';

/**
 * Verifies the request's bearer token and superAdmin role.
 * Returns the caller's uid on success; throws HttpError(401|403) on
 * failure.
 */
export async function requireSuperAdmin(request, env) {
  const authHeader = request.headers.get('authorization') || '';
  const match = authHeader.match(/^Bearer\s+(.+)$/i);
  if (!match) throw new HttpError(401, 'Missing bearer token');

  let uid;
  try {
    const claims = await verifyFirebaseIdToken(match[1]);
    uid = claims.sub;
  } catch (err) {
    throw new HttpError(401, 'Invalid or expired token');
  }

  let userDoc;
  try {
    userDoc = await getDoc(env, 'users', uid);
  } catch (err) {
    throw new HttpError(500, 'Failed to look up user role');
  }

  if (!userDoc || userDoc.role !== 'superAdmin') {
    throw new HttpError(403, 'Not authorized');
  }

  return uid;
}
