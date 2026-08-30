// Shared JWT/crypto helpers built on the Workers-native Web Crypto API
// (SubtleCrypto) — no npm dependencies needed for RS256 sign/verify.

/** Base64url-encode an ArrayBuffer or Uint8Array. */
export function base64UrlEncode(data) {
  const bytes = data instanceof ArrayBuffer ? new Uint8Array(data) : data;
  let binary = '';
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/** Base64url-encode a UTF-8 string (for JWT header/payload segments). */
export function base64UrlEncodeString(str) {
  return base64UrlEncode(new TextEncoder().encode(str));
}

/** Decode a base64url string to a Uint8Array. */
export function base64UrlDecode(str) {
  const padded = str.replace(/-/g, '+').replace(/_/g, '/');
  const pad = padded.length % 4 === 0 ? '' : '='.repeat(4 - (padded.length % 4));
  const binary = atob(padded + pad);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

/** Decode a base64url JWT segment as JSON. */
export function base64UrlDecodeJson(str) {
  return JSON.parse(new TextDecoder().decode(base64UrlDecode(str)));
}

/**
 * Converts a PEM-encoded PKCS8 private key (as delivered in a Firebase
 * service-account JSON, e.g. via `env.FIREBASE_PRIVATE_KEY`) into a
 * CryptoKey usable for RS256 signing.
 *
 * Handles both real newlines and literal "\n" escape sequences, since
 * Wrangler secrets set from a shell often arrive with escaped newlines.
 */
export async function importPrivateKey(pem) {
  const normalized = pem.includes('\\n') ? pem.replace(/\\n/g, '\n') : pem;
  const pemBody = normalized
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '');
  const der = base64UrlDecodeStandard(pemBody);
  return crypto.subtle.importKey(
    'pkcs8',
    der,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

/** Standard (non-urlsafe) base64 decode, used for PEM bodies. */
function base64UrlDecodeStandard(b64) {
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

/**
 * Imports a PEM-encoded X.509 certificate's RSA public key (as returned by
 * Google's Firebase Auth cert endpoint) for RS256 signature verification.
 *
 * Web Crypto's `importKey` can't parse a raw X.509 certificate directly —
 * it only accepts a bare `SubjectPublicKeyInfo` (spki) structure. So we
 * walk the certificate's outer DER/ASN.1 SEQUENCEs (Certificate ->
 * tbsCertificate -> ... -> subjectPublicKeyInfo) far enough to slice out
 * just that inner structure, then hand it to `importKey('spki', ...)`.
 */
export async function importCertPublicKey(pem) {
  const pemBody = pem
    .replace('-----BEGIN CERTIFICATE-----', '')
    .replace('-----END CERTIFICATE-----', '')
    .replace(/\s+/g, '');
  const certDer = base64UrlDecodeStandard(pemBody);
  const spki = extractSpkiFromCertificate(certDer);
  return crypto.subtle.importKey(
    'spki',
    spki,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );
}

// --- Minimal DER/ASN.1 walker -------------------------------------------
// X.509 certificates are DER-encoded ASN.1. We only need to pull out the
// `SubjectPublicKeyInfo` (SPKI) sub-structure, which is exactly what
// `crypto.subtle.importKey('spki', ...)` expects. Writing a tiny walker
// avoids pulling in a full ASN.1 parsing library for this one field.

function readTlv(bytes, offset) {
  const tag = bytes[offset];
  let lenByte = bytes[offset + 1];
  let lenOffset = offset + 2;
  let length;
  if (lenByte & 0x80) {
    const numLenBytes = lenByte & 0x7f;
    length = 0;
    for (let i = 0; i < numLenBytes; i++) {
      length = (length << 8) | bytes[lenOffset + i];
    }
    lenOffset += numLenBytes;
  } else {
    length = lenByte;
  }
  return { tag, valueStart: lenOffset, valueEnd: lenOffset + length };
}

function extractSpkiFromCertificate(certDer) {
  // Certificate ::= SEQUENCE { tbsCertificate, signatureAlgorithm, signature }
  const cert = readTlv(certDer, 0);
  // tbsCertificate ::= SEQUENCE { version, serialNumber, signature,
  //   issuer, validity, subject, subjectPublicKeyInfo, ... }
  const tbs = readTlv(certDer, cert.valueStart);

  let pos = tbs.valueStart;
  // version is an explicit context tag [0] wrapping an INTEGER — optional,
  // but Firebase certs always include it.
  let field = readTlv(certDer, pos);
  if (field.tag === 0xa0) {
    pos = field.valueEnd; // skip version
    field = readTlv(certDer, pos); // serialNumber
  }
  pos = field.valueEnd; // after serialNumber
  field = readTlv(certDer, pos); // signature AlgorithmIdentifier
  pos = field.valueEnd;
  field = readTlv(certDer, pos); // issuer Name
  pos = field.valueEnd;
  field = readTlv(certDer, pos); // validity
  pos = field.valueEnd;
  field = readTlv(certDer, pos); // subject Name
  pos = field.valueEnd;
  field = readTlv(certDer, pos); // subjectPublicKeyInfo — this is what we want

  return certDer.slice(pos, field.valueEnd);
}

/**
 * Builds and RS256-signs a JWT from a header-less payload object (the
 * standard `{alg:"RS256",typ:"JWT"}` header is added automatically).
 * Used both for the Firestore/OAuth service-account JWT-bearer assertion.
 */
export async function signJwt(payload, privateKeyPem) {
  const header = { alg: 'RS256', typ: 'JWT' };
  const encodedHeader = base64UrlEncodeString(JSON.stringify(header));
  const encodedPayload = base64UrlEncodeString(JSON.stringify(payload));
  const signingInput = `${encodedHeader}.${encodedPayload}`;

  const key = await importPrivateKey(privateKeyPem);
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(signingInput),
  );

  return `${signingInput}.${base64UrlEncode(signature)}`;
}

/**
 * Verifies an RS256 JWT's signature against a given public CryptoKey.
 * Does NOT check claims (exp/iss/aud) — callers do that separately.
 */
export async function verifyJwtSignature(token, publicKey) {
  const parts = token.split('.');
  if (parts.length !== 3) return false;
  const [encodedHeader, encodedPayload, encodedSignature] = parts;
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const signature = base64UrlDecode(encodedSignature);
  return crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    publicKey,
    signature,
    new TextEncoder().encode(signingInput),
  );
}

export function decodeJwt(token) {
  const [encodedHeader, encodedPayload] = token.split('.');
  return {
    header: base64UrlDecodeJson(encodedHeader),
    payload: base64UrlDecodeJson(encodedPayload),
  };
}
