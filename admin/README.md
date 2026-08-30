# Mening Mahallam — Admin

Super-admin dashboard for the "Mening Mahallam" app. A lightweight static SPA built with Vite + TypeScript (no framework), using Firebase Auth for login and a Cloudflare Worker backend (`admin-worker/`) for data.

## Stack

- Vite + TypeScript (vanilla, no React/Vue)
- Firebase JS SDK (`firebase/auth`) for email/password login
- Plain CSS (dark theme, sidebar layout)
- Hash-based client-side routing

## Setup

```bash
cd admin
npm install
```

## Development

```bash
npm run dev
```

Opens on `http://localhost:5173`. By default it talks to the backend API at `http://localhost:8787` (i.e. `wrangler dev` for `admin-worker/`). Override this by creating an `.env.local` file:

```
VITE_API_BASE_URL=https://your-worker-url
```

`.env.local` is gitignored and takes precedence over the committed `.env` default.

## Login

Sign in with an existing Firebase Auth account for this project. The account's Firestore `users/{uid}` document must have `role: 'superAdmin'` set (done manually via the Firebase Console — this app does not manage that). If the backend rejects a request with 401/403, the app signs you out automatically.

## Build

```bash
npm run build
```

Produces a static site in `dist/`, ready to deploy to Cloudflare Pages.

## Preview a production build locally

```bash
npm run preview
```

## Pages

- **Kirish (Login)** — email/password sign-in via Firebase Auth.
- **Bosh sahifa (Dashboard)** — stat cards from `GET /api/stats`, with a freshness timestamp (data refreshes ~every 30 min).
- **Mahallalar** — table of all mahallas from `GET /api/mahallas`.
- **Premium so'rovlar** — pending premium requests with Approve/Reject actions.
- **Bannerlar** — list + delete of ad banners, plus a form to add a new one (image/link URL + order — no file upload, images must already be hosted elsewhere).
- **Shikoyatlar** — pending reports with "Ko'rib chiqildi" (reviewed) / "Rad etildi" (dismissed) resolution actions.
