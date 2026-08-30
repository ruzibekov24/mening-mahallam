// Audit-log helper: writes a doc to the top-level `adminAuditLog`
// Firestore collection every time a superAdmin performs a mutating
// action through this Worker. This collection is written ONLY by this
// Worker's service-account credentials (which bypass Firestore Security
// Rules entirely) — `firestore.rules` has a matching
// `match /adminAuditLog/{logId}` block with `allow write: if false`, so
// no mobile client can ever write or forge an entry; its `allow read: if
// isSuperAdmin()` is what backs `GET /api/audit-log`.

import { createDoc } from './firestore.js';

/**
 * Logs one admin action. Never throws — a failure to write the audit
 * log must never break the actual admin action it's describing, so any
 * error here is caught and just `console.error`'d.
 *
 * @param {string} actorUid - calling superAdmin's uid.
 * @param {string} action - short dotted action string, e.g.
 *   "banner.create", "premium.grant", "user.role.update".
 * @param {object} details - small JSON-serializable object with
 *   whatever's relevant to the action (targetId, mahallaId, etc).
 */
export async function logAudit(env, actorUid, action, details) {
  try {
    await createDoc(env, 'adminAuditLog', {
      actorUid,
      action,
      details: details || {},
      timestamp: new Date(),
    });
  } catch (err) {
    console.error('Audit log write failed:', action, err);
  }
}
