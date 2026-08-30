import { login } from '../lib/firebase';

export function renderLogin(root: HTMLElement): void {
  root.innerHTML = `
    <div class="login-screen">
      <div class="login-card">
        <h1>Mening Mahallam</h1>
        <p class="subtitle">Super-admin panelga kirish</p>
        <div id="login-error"></div>
        <form id="login-form">
          <div class="field">
            <label for="email">Email</label>
            <input type="email" id="email" name="email" required autocomplete="username" />
          </div>
          <div class="field">
            <label for="password">Parol</label>
            <input type="password" id="password" name="password" required autocomplete="current-password" />
          </div>
          <button type="submit" class="btn btn-block" id="login-btn">Kirish</button>
        </form>
      </div>
    </div>
  `;

  const form = root.querySelector<HTMLFormElement>('#login-form')!;
  const errorBox = root.querySelector<HTMLDivElement>('#login-error')!;
  const submitBtn = root.querySelector<HTMLButtonElement>('#login-btn')!;

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    errorBox.innerHTML = '';
    const email = (form.elements.namedItem('email') as HTMLInputElement).value.trim();
    const password = (form.elements.namedItem('password') as HTMLInputElement).value;

    submitBtn.disabled = true;
    submitBtn.innerHTML = '<span class="spinner"></span> Kirilmoqda...';

    try {
      await login(email, password);
      // onAuthStateChanged in main.ts will handle navigation.
    } catch (err) {
      const message = mapFirebaseError(err);
      errorBox.innerHTML = `<div class="error-banner">${message}</div>`;
      submitBtn.disabled = false;
      submitBtn.textContent = 'Kirish';
    }
  });
}

function mapFirebaseError(err: unknown): string {
  const code = (err as { code?: string })?.code ?? '';
  switch (code) {
    case 'auth/invalid-email':
      return 'Email manzili noto‘g‘ri.';
    case 'auth/user-not-found':
    case 'auth/wrong-password':
    case 'auth/invalid-credential':
      return 'Email yoki parol noto‘g‘ri.';
    case 'auth/too-many-requests':
      return 'Urinishlar soni ko‘p. Birozdan so‘ng qayta urining.';
    case 'auth/network-request-failed':
      return 'Tarmoq xatoligi. Internet aloqasini tekshiring.';
    default:
      return 'Xatolik: kirib bo‘lmadi. Qaytadan urinib ko‘ring.';
  }
}
