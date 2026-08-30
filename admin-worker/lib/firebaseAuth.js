// Verifies Firebase ID tokens sent by the admin frontend as
// `Authorization: Bearer <token>`, per Firebase's documented manual
// verification procedure (see
// https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library).

import { decodeJwt, importCertPublicKey, verifyJwtSignature } from './jwt.js';

const CERTS_URL =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

const FIREBASE_PROJECT_ID = 'mahallam-d4a93';
const EXPECTED_ISSUER = `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`;

// Module-level cache — persists across requests handled by the same
// Worker isolate (isolates are reused between requests, so this avoids
// refetching Google's certs on every single API call). Respects the
// endpoint's Cache-Control max-age.
let certCache = { certs: null, expiresAt: 0 };

async function fetchCerts() {
  const now = Date.now();
  if (certCache.certs && certCache.expiresAt > now) {
    return certCache.certs;
  }

  const res = await fetch(CERTS_URL);
  if (!res.ok) {
    throw new Error(`Failed to fetch Firebase certs: ${res.status}`);
  }
  const certs = await res.json(); // { [kid]: PEM certificate string }

  // Parse Cache-Control max-age to know how long these certs are valid
  // for (Google rotates them periodically); fall back to 1 hour if the
  // header is missing or unparsable.
  const cacheControl = res.headers.get('cache-control') || '';
  const match = cacheControl.match(/max-age=(\d+)/);
  const maxAgeSeconds = match ? parseInt(match[1], 10) : 3600;

  certCache = { certs, expiresAt: now + maxAgeSeconds * 1000 };
  return certs;
}

/**
 * Verifies a Firebase ID token's signature and standard claims.
 * Returns the decoded payload (including `sub` = uid) on success, or
 * throws an Error with a short, safe-to-return message on failure.
 */
export async function verifyFirebaseIdToken(token) {
  if (!token) throw new Error('Missing token');

  let header, payload;
  try {
    ({ header, payload } = decodeJwt(token));
  } catch {
    throw new Error('Malformed token');
  }

  if (header.alg !== 'RS256') throw new Error('Unexpected token algorithm');
  if (!header.kid) throw new Error('Token missing kid');

  const certs = await fetchCerts();
  const certPem = certs[header.kid];
  if (!certPem) throw new Error('Unknown token signing key');

  const publicKey = await importCertPublicKey(certPem);
  const validSignature = await verifyJwtSignature(token, publicKey);
  if (!validSignature) throw new Error('Invalid token signature');

  const nowSeconds = Math.floor(Date.now() / 1000);
  if (typeof payload.exp !== 'number' || payload.exp <= nowSeconds) {
    throw new Error('Token expired');
  }
  if (typeof payload.iat !== 'number' || payload.iat > nowSeconds + 60) {
    throw new Error('Token issued in the future');
  }
  if (payload.iss !== EXPECTED_ISSUER) {
    throw new Error('Unexpected token issuer');
  }
  if (payload.aud !== FIREBASE_PROJECT_ID) {
    throw new Error('Unexpected token audience');
  }
  if (!payload.sub || typeof payload.sub !== 'string') {
    throw new Error('Token missing subject');
  }

  return payload; // payload.sub is the Firebase uid
}
