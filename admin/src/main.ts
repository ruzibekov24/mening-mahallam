import { watchAuth, type User } from './lib/firebase';
import { renderLogin } from './pages/login';
import { renderLayout, setActiveNav } from './layout';
import { renderDashboard } from './pages/dashboard';
import { renderMahallalar } from './pages/mahallalar';
import { renderPremium } from './pages/premium';
import { renderBannerlar } from './pages/bannerlar';
import { renderShikoyatlar } from './pages/shikoyatlar';
import { renderAnnouncements } from './pages/announcements';
import { renderMurojaatlar } from './pages/murojaatlar';
import { renderFoydalanuvchilar } from './pages/foydalanuvchilar';
import { renderSorovnomalar } from './pages/sorovnomalar';
import { renderXizmatlar } from './pages/xizmatlar';
import { renderXizmatlarRoyxati } from './pages/xizmatlar-royxati';
import { renderMahallaDetail } from './pages/mahalla-detail';
import { renderAuditLog } from './pages/audit-log';

const root = document.getElementById('app')!;

type PageRenderer = (container: HTMLElement, params: Record<string, string>) => void | Promise<void>;

// Static routes match the hash exactly. A route path may also contain
// `:param` segments (e.g. '#/mahallalar/:id') — matched against the actual
// hash by splitting on '/' and comparing segment-by-segment.
const ROUTES: Record<string, PageRenderer> = {
  '#/dashboard': renderDashboard,
  '#/mahallalar': renderMahallalar,
  '#/mahallalar/:id': renderMahallaDetail,
  '#/premium': renderPremium,
  '#/bannerlar': renderBannerlar,
  '#/shikoyatlar': renderShikoyatlar,
  '#/announcements': renderAnnouncements,
  '#/murojaatlar': renderMurojaatlar,
  '#/foydalanuvchilar': renderFoydalanuvchilar,
  '#/sorovnomalar': renderSorovnomalar,
  '#/xizmatlar': renderXizmatlarRoyxati,
  '#/reklama-elonlari': renderXizmatlar,
  '#/audit-log': renderAuditLog,
};

const ROUTE_PATHS = Object.keys(ROUTES);

let currentUser: User | null = null;
let mainEl: HTMLElement | null = null;

function matchRoute(hash: string): { path: string; params: Record<string, string> } | null {
  const hashSegments = hash.split('/');
  for (const path of ROUTE_PATHS) {
    const pathSegments = path.split('/');
    if (pathSegments.length !== hashSegments.length) continue;
    const params: Record<string, string> = {};
    let matched = true;
    for (let i = 0; i < pathSegments.length; i++) {
      const pSeg = pathSegments[i];
      const hSeg = hashSegments[i];
      if (pSeg.startsWith(':')) {
        params[pSeg.slice(1)] = decodeURIComponent(hSeg);
      } else if (pSeg !== hSeg) {
        matched = false;
        break;
      }
    }
    if (matched) return { path, params };
  }
  return null;
}

function normalizedHash(): { path: string; params: Record<string, string> } {
  const hash = window.location.hash || '#/dashboard';
  return matchRoute(hash) ?? { path: '#/dashboard', params: {} };
}

function router(): void {
  if (!currentUser || !mainEl) return;
  const { path, params } = normalizedHash();
  const targetHash = Object.keys(params).length
    ? window.location.hash
    : path;
  if (window.location.hash !== targetHash) {
    window.location.hash = targetHash;
    return;
  }
  setActiveNav(root, path);
  void ROUTES[path](mainEl, params);
}

function showApp(user: User): void {
  mainEl = renderLayout(root, user.email);
  router();
}

function showLogin(): void {
  mainEl = null;
  renderLogin(root);
}

watchAuth((user) => {
  currentUser = user;
  if (user) {
    showApp(user);
  } else {
    showLogin();
  }
});

window.addEventListener('hashchange', router);
