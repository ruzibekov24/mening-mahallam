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

const root = document.getElementById('app')!;

type PageRenderer = (container: HTMLElement) => void | Promise<void>;

const ROUTES: Record<string, PageRenderer> = {
  '#/dashboard': renderDashboard,
  '#/mahallalar': renderMahallalar,
  '#/premium': renderPremium,
  '#/bannerlar': renderBannerlar,
  '#/shikoyatlar': renderShikoyatlar,
  '#/announcements': renderAnnouncements,
  '#/murojaatlar': renderMurojaatlar,
  '#/foydalanuvchilar': renderFoydalanuvchilar,
  '#/sorovnomalar': renderSorovnomalar,
  '#/xizmatlar': renderXizmatlarRoyxati,
  '#/reklama-elonlari': renderXizmatlar,
};

let currentUser: User | null = null;
let mainEl: HTMLElement | null = null;

function normalizedHash(): string {
  const hash = window.location.hash || '#/dashboard';
  return ROUTES[hash] ? hash : '#/dashboard';
}

function router(): void {
  if (!currentUser || !mainEl) return;
  const path = normalizedHash();
  if (window.location.hash !== path) {
    window.location.hash = path;
    return;
  }
  setActiveNav(root, path);
  void ROUTES[path](mainEl);
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
