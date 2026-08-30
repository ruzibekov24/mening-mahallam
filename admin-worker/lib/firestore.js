// Minimal Firestore REST API client. Firestore's REST API represents
// field values as tagged objects (e.g. `{stringValue: "x"}` instead of
// plain `"x"`) — the encode/decode helpers below translate to/from plain
// JS values so the rest of the codebase can work with ordinary objects.

import { getAccessToken } from './googleAuth.js';

const BASE = 'https://firestore.googleapis.com/v1';

function projectRoot(env) {
  return `projects/${env.FIREBASE_PROJECT_ID}/databases/(default)`;
}

function documentsRoot(env) {
  return `${projectRoot(env)}/documents`;
}

async function fsFetch(env, url, options = {}) {
  const accessToken = await getAccessToken(env);
  const res = await fetch(url, {
    ...options,
    headers: {
      authorization: `Bearer ${accessToken}`,
      'content-type': 'application/json',
      ...(options.headers || {}),
    },
  });
  return res;
}

// --- Value encode/decode -------------------------------------------------

/** Converts a plain JS value into a Firestore REST "Value" object. */
export function encodeValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(encodeValue) } };
  }
  if (typeof value === 'object') {
    return { mapValue: { fields: encodeFields(value) } };
  }
  throw new Error(`Cannot encode Firestore value: ${typeof value}`);
}

/** Converts a plain JS object's own fields into Firestore REST "fields". */
export function encodeFields(obj) {
  const fields = {};
  for (const [key, value] of Object.entries(obj)) {
    if (value === undefined) continue; // omit, rather than write null
    fields[key] = encodeValue(value);
  }
  return fields;
}

/** Converts a single Firestore REST "Value" object into a plain JS value. */
export function decodeValue(value) {
  if (!value) return null;
  if ('nullValue' in value) return null;
  if ('stringValue' in value) return value.stringValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('integerValue' in value) return parseInt(value.integerValue, 10);
  if ('doubleValue' in value) return value.doubleValue;
  if ('timestampValue' in value) return value.timestampValue; // ISO string
  if ('arrayValue' in value) {
    return (value.arrayValue.values || []).map(decodeValue);
  }
  if ('mapValue' in value) {
    return decodeFields(value.mapValue.fields || {});
  }
  if ('referenceValue' in value) return value.referenceValue;
  if ('geoPointValue' in value) return value.geoPointValue;
  return null;
}

/** Converts a Firestore REST document's "fields" map into a plain object. */
export function decodeFields(fields) {
  const obj = {};
  for (const [key, value] of Object.entries(fields || {})) {
    obj[key] = decodeValue(value);
  }
  return obj;
}

/** Extracts the trailing document id from a full Firestore resource name. */
export function docIdFromName(name) {
  return name.substring(name.lastIndexOf('/') + 1);
}

/** Decodes a Firestore REST "Document" into `{id, ...fields}`. */
function decodeDoc(doc) {
  return { id: docIdFromName(doc.name), ...decodeFields(doc.fields) };
}

// --- CRUD ------------------------------------------------------------

/** Reads a single document by collection + id. Returns null if missing. */
export async function getDoc(env, collection, id) {
  const res = await fsFetch(env, `${BASE}/${documentsRoot(env)}/${collection}/${id}`);
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`Firestore getDoc failed: ${res.status}`);
  const doc = await res.json();
  return decodeDoc(doc);
}

/**
 * Lists all documents in a top-level collection (simple, unfiltered —
 * good enough for the small admin collections used here: mahallas,
 * promoBanners). For filtered queries use `runQuery`.
 */
export async function listCollection(env, collection, { pageSize = 300 } = {}) {
  const docs = [];
  let pageToken;
  do {
    const url = new URL(`${BASE}/${documentsRoot(env)}/${collection}`);
    url.searchParams.set('pageSize', String(pageSize));
    if (pageToken) url.searchParams.set('pageToken', pageToken);
    const res = await fsFetch(env, url.toString());
    if (!res.ok) throw new Error(`Firestore listCollection failed: ${res.status}`);
    const data = await res.json();
    for (const doc of data.documents || []) docs.push(decodeDoc(doc));
    pageToken = data.nextPageToken;
  } while (pageToken);
  return docs;
}

/**
 * Runs a structured query against a collection, e.g. for
 * `premiumRequests` filtered by `status`. `structuredQuery` follows
 * Firestore's StructuredQuery REST shape; `parentPath` defaults to the
 * documents root (top-level collections).
 *
 * Pass `{ includeMahallaId: true }` in `opts` for collection-group
 * queries (`allDescendants: true`) run at the documents root — each
 * returned doc gets a `mahallaId` field parsed out of the full
 * `mahallas/{mahallaId}/...` resource path, since `decodeDoc` alone only
 * keeps the trailing document id and would otherwise lose which mahalla
 * the doc came from.
 */
export async function runQuery(env, structuredQuery, parentPath = '', opts = {}) {
  const url = `${BASE}/${documentsRoot(env)}${parentPath ? '/' + parentPath : ''}:runQuery`;
  const res = await fsFetch(env, url, {
    method: 'POST',
    body: JSON.stringify({ structuredQuery }),
  });
  if (!res.ok) throw new Error(`Firestore runQuery failed: ${res.status}`);
  const rows = await res.json();
  return rows
    .filter((r) => r.document)
    .map((r) => {
      const doc = decodeDoc(r.document);
      if (opts.includeMahallaId) {
        const match = r.document.name.match(/\/mahallas\/([^/]+)\//);
        doc.mahallaId = match ? match[1] : null;
      }
      return doc;
    });
}

/**
 * Runs an aggregation query (e.g. COUNT) — used by the stats cron job.
 * Returns the raw aggregate result map, e.g. `{count: 42}`.
 */
export async function runAggregationQuery(env, structuredQuery, parentPath = '') {
  const url = `${BASE}/${documentsRoot(env)}${parentPath ? '/' + parentPath : ''}:runAggregationQuery`;
  const res = await fsFetch(env, url, {
    method: 'POST',
    body: JSON.stringify({ structuredAggregationQuery: {
      structuredQuery,
      aggregations: [{ alias: 'count', count: {} }],
    } }),
  });
  if (!res.ok) throw new Error(`Firestore runAggregationQuery failed: ${res.status}`);
  const rows = await res.json();
  const result = rows.find((r) => r.result)?.result;
  const countValue = result?.aggregateFields?.count;
  return countValue ? decodeValue(countValue) : 0;
}

/** Creates a new document with an auto-generated id in `collection`. */
export async function createDoc(env, collection, fields) {
  const res = await fsFetch(env, `${BASE}/${documentsRoot(env)}/${collection}`, {
    method: 'POST',
    body: JSON.stringify({ fields: encodeFields(fields) }),
  });
  if (!res.ok) throw new Error(`Firestore createDoc failed: ${res.status}`);
  const doc = await res.json();
  return decodeDoc(doc);
}

/**
 * Sentinel value for `patchDoc` — pass this as a field's value to delete
 * that field from the document entirely (mirrors the Flutter app's
 * `FieldValue.delete()`, e.g. `PremiumRepository.revokePremium`'s
 * `{'premiumUntil': FieldValue.delete()}`). The field's key is still
 * listed in `updateMask.fieldPaths` (so Firestore knows to touch it) but
 * omitted from the request body's `fields`, which is exactly how the
 * Firestore REST API represents "remove this field" — as opposed to
 * setting it to `null` (which keeps the field, with a null value).
 */
export const FieldDelete = Symbol('FieldDelete');

/**
 * Updates (merges) fields on an existing document. Only the fields
 * listed in `fields` are touched — Firestore's `updateMask.fieldPaths`
 * ensures other fields on the document are left untouched, matching
 * `SetOptions(merge: true)` / `.update()` semantics in the Flutter app.
 * See `FieldDelete` above to delete a field instead of setting it.
 */
export async function patchDoc(env, collection, id, fields) {
  const mask = Object.keys(fields)
    .map((key) => `updateMask.fieldPaths=${encodeURIComponent(key)}`)
    .join('&');
  const writeFields = {};
  for (const [key, value] of Object.entries(fields)) {
    if (value === FieldDelete) continue; // in mask, absent from fields -> deleted
    writeFields[key] = value;
  }
  const url = `${BASE}/${documentsRoot(env)}/${collection}/${id}?${mask}`;
  const res = await fsFetch(env, url, {
    method: 'PATCH',
    body: JSON.stringify({ fields: encodeFields(writeFields) }),
  });
  if (!res.ok) throw new Error(`Firestore patchDoc failed: ${res.status}`);
  const doc = await res.json();
  return decodeDoc(doc);
}

/** Deletes a document. Succeeds silently if it doesn't exist. */
export async function deleteDoc(env, collection, id) {
  const res = await fsFetch(env, `${BASE}/${documentsRoot(env)}/${collection}/${id}`, {
    method: 'DELETE',
  });
  if (!res.ok && res.status !== 404) {
    throw new Error(`Firestore deleteDoc failed: ${res.status}`);
  }
}
