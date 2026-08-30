import { initializeApp } from 'firebase/app';
import {
  getAuth,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  type User,
} from 'firebase/auth';

// Public client identifiers for the Mening Mahallam Firebase project.
// Firebase security is enforced server-side via Firestore rules and the
// backend Worker, not by hiding these values.
const firebaseConfig = {
  apiKey: 'AIzaSyA4ZUgfAvkqQSgoB9jvKcjqHPZeNV8I8HQ',
  authDomain: 'mahallam-d4a93.firebaseapp.com',
  projectId: 'mahallam-d4a93',
  storageBucket: 'mahallam-d4a93.firebasestorage.app',
  messagingSenderId: '831011690237',
  appId: '1:831011690237:web:9c3a467d1d44275cc8d094',
  measurementId: 'G-QL12TR61YH',
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);

export async function login(email: string, password: string): Promise<void> {
  await signInWithEmailAndPassword(auth, email, password);
}

export async function logout(): Promise<void> {
  await signOut(auth);
}

export function watchAuth(callback: (user: User | null) => void): () => void {
  return onAuthStateChanged(auth, callback);
}

/** Always fetches a fresh ID token — never persisted to localStorage. */
export async function getIdToken(): Promise<string | null> {
  const user = auth.currentUser;
  if (!user) return null;
  return user.getIdToken();
}

export type { User };
