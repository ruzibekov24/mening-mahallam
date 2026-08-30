import { logout } from './lib/firebase';

export interface NavItem {
  path: string;
  label: string;
}

export const NAV_ITEMS: NavItem[] = [
  { path: '#/dashboard', label: 'Bosh sahifa' },
  { path: '#/mahallalar', label: 'Mahallalar' },
  { path: '#/premium', label: "Premium so'rovlar" },
  { path: '#/bannerlar', label: 'Bannerlar' },
  { path: '#/shikoyatlar', label: 'Shikoyatlar' },
];

export function renderLayout(root: HTMLElement, userEmail: string | null): HTMLElement {
  root.innerHTML = `
    <div class="layout">
      <aside class="sidebar">
        <div class="brand">
          Mening Mahallam
          <small>Super-admin panel</small>
        </div>
        <nav id="sidebar-nav">
          ${NAV_ITEMS.map(
            (item) => `<a class="nav-link" href="${item.path}" data-path="${item.path}">${item.label}</a>`
          ).join('')}
        </nav>
        <div class="sidebar-footer">
          <div class="user-email">${userEmail ?? ''}</div>
          <button class="btn btn-secondary btn-block" id="logout-btn">Chiqish</button>
        </div>
      </aside>
      <main class="main" id="main-content"></main>
    </div>
  `;

  root.querySelector<HTMLButtonElement>('#logout-btn')!.addEventListener('click', async () => {
    await logout();
  });

  return root.querySelector<HTMLElement>('#main-content')!;
}

export function setActiveNav(root: HTMLElement, currentPath: string): void {
  root.querySelectorAll<HTMLAnchorElement>('.nav-link').forEach((link) => {
    link.classList.toggle('active', link.dataset.path === currentPath);
  });
}
