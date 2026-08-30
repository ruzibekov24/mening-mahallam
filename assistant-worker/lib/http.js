// Small HTTP helpers: CORS headers, JSON responses, and a uniform error
// shape that never leaks stack traces or secret values to the client.

export function corsHeaders(env) {
  return {
    // TODO: tighten this to the real admin frontend origin (e.g. the
    // Cloudflare Pages domain) once it's known — wildcard is a stopgap
    // since the API is behind Firebase-auth + superAdmin-role checks
    // regardless, but least-privilege CORS is still worth doing.
    'access-control-allow-origin': env.ALLOWED_ORIGIN || '*',
    'access-control-allow-methods': 'GET, POST, PATCH, DELETE, OPTIONS',
    'access-control-allow-headers': 'authorization, content-type',
    'access-control-max-age': '86400',
  };
}

export function jsonResponse(data, status, env) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'content-type': 'application/json', ...corsHeaders(env) },
  });
}

/** A structured error the route handlers can `throw` and have handled
 * uniformly by the top-level fetch handler. */
export class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

export function handleOptions(env) {
  return new Response(null, { status: 204, headers: corsHeaders(env) });
}
