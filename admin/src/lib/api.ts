import { auth, getIdToken, logout } from './firebase';

const BASE_URL: string = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8787';

export class ApiError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = await getIdToken();
  if (!token) {
    throw new ApiError(401, 'Tizimga kirilmagan.');
  }

  const res = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
      ...(options.headers || {}),
    },
  });

  if (res.status === 401 || res.status === 403) {
    // Not authenticated or not a superAdmin — sign the user out.
    try {
      await logout();
    } catch {
      // ignore
    }
    throw new ApiError(
      res.status,
      res.status === 403
        ? 'Sizda administrator huquqlari yo’q.'
        : 'Sessiya tugagan. Qaytadan kiring.'
    );
  }

  if (!res.ok) {
    let message = `Server xatoligi (${res.status})`;
    try {
      const body = await res.json();
      if (body && typeof body.message === 'string') message = body.message;
    } catch {
      // ignore body parse errors
    }
    throw new ApiError(res.status, message);
  }

  if (res.status === 204) {
    return undefined as T;
  }

  const contentType = res.headers.get('content-type') || '';
  if (!contentType.includes('application/json')) {
    return undefined as T;
  }
  return (await res.json()) as T;
}

export interface Stats {
  total_mahallas: number;
  total_users: number;
  total_active_requests: number;
  total_pending_premium: number;
  updated_at: string;
}

export interface Mahalla {
  id: string;
  name: string;
  [key: string]: unknown;
}

export interface PremiumRequest {
  id: string;
  uid: string;
  status: string;
  createdAt: string;
  displayName?: string;
  phone?: string;
  [key: string]: unknown;
}

export interface Banner {
  id: string;
  imageUrl: string;
  linkUrl?: string;
  order: number;
}

export interface Report {
  id: string;
  reporterUid: string;
  targetType: string;
  targetId: string;
  reason: string;
  status: string;
  createdAt: string;
  mahallaId: string;
}

export const api = {
  getStats: () => request<Stats>('/api/stats'),
  getMahallas: () => request<Mahalla[]>('/api/mahallas'),
  getPremiumRequests: (status = 'pending') =>
    request<PremiumRequest[]>(`/api/premium-requests?status=${encodeURIComponent(status)}`),
  approvePremiumRequest: (id: string) =>
    request<void>(`/api/premium-requests/${encodeURIComponent(id)}/approve`, { method: 'POST' }),
  rejectPremiumRequest: (id: string) =>
    request<void>(`/api/premium-requests/${encodeURIComponent(id)}/reject`, { method: 'POST' }),
  getBanners: () => request<Banner[]>('/api/banners'),
  createBanner: (data: { imageUrl: string; linkUrl?: string; order: number }) =>
    request<void>('/api/banners', { method: 'POST', body: JSON.stringify(data) }),
  deleteBanner: (id: string) =>
    request<void>(`/api/banners/${encodeURIComponent(id)}`, { method: 'DELETE' }),
  getReports: (status = 'pending') =>
    request<Report[]>(`/api/reports?status=${encodeURIComponent(status)}`),
  resolveReport: (id: string, outcome: 'reviewed' | 'dismissed') =>
    request<void>(`/api/reports/${encodeURIComponent(id)}/resolve`, {
      method: 'POST',
      body: JSON.stringify({ outcome }),
    }),
};

export function currentUserEmail(): string | null {
  return auth.currentUser?.email ?? null;
}
