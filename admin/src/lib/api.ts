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

export interface Announcement {
  id: string;
  mahallaId: string;
  title: string;
  body?: string;
  category?: string;
  createdAt: string;
  imageUrl?: string;
  authorUid?: string;
  reactedUids?: Record<string, string>;
  [key: string]: unknown;
}

export interface MahallaEvent {
  id: string;
  mahallaId: string;
  title: string;
  dateTime: string;
  location?: string;
  participantsCount?: number;
  createdAt?: string;
  authorUid?: string;
  [key: string]: unknown;
}

export interface MurojaatRequest {
  id: string;
  mahallaId: string;
  title: string;
  description?: string;
  status: string;
  type?: string;
  priority?: string;
  joinedCount?: number;
  joinedUids?: string[];
  createdAt: string;
  authorUid?: string;
  [key: string]: unknown;
}

export interface Poll {
  id: string;
  mahallaId: string;
  question: string;
  options: string[];
  authorUid?: string;
  createdAt: string;
  allowMultiple?: boolean;
  isAnonymous?: boolean;
  closesAt?: string | null;
  votes?: Record<string, number | number[]>;
  results: { voteCounts: number[]; totalVotes: number };
  [key: string]: unknown;
}

export interface ServiceAd {
  id: string;
  mahallaId: string;
  title: string;
  description?: string;
  phone?: string;
  ownerName?: string;
  activeUntil?: string;
  createdAt?: string;
  [key: string]: unknown;
}

export interface AdminUser {
  id: string;
  firstName?: string;
  lastName?: string;
  phone?: string;
  mahallaId?: string;
  role: string;
  staffTitle?: string | null;
  verifiedBadge?: boolean;
  premiumUntil?: string | null;
  [key: string]: unknown;
}

export const api = {
  getStats: () => request<Stats>('/api/stats'),
  getMahallas: () => request<{ mahallas: Mahalla[] }>('/api/mahallas').then((r) => r.mahallas),
  getPremiumRequests: (status = 'pending') =>
    request<{ premiumRequests: PremiumRequest[] }>(
      `/api/premium-requests?status=${encodeURIComponent(status)}`
    ).then((r) => r.premiumRequests),
  approvePremiumRequest: (id: string) =>
    request<void>(`/api/premium-requests/${encodeURIComponent(id)}/approve`, { method: 'POST' }),
  rejectPremiumRequest: (id: string) =>
    request<void>(`/api/premium-requests/${encodeURIComponent(id)}/reject`, { method: 'POST' }),
  getBanners: () => request<{ banners: Banner[] }>('/api/banners').then((r) => r.banners),
  createBanner: (data: { imageUrl: string; linkUrl?: string; order: number }) =>
    request<void>('/api/banners', { method: 'POST', body: JSON.stringify(data) }),
  deleteBanner: (id: string) =>
    request<void>(`/api/banners/${encodeURIComponent(id)}`, { method: 'DELETE' }),
  getReports: (status = 'pending') =>
    request<{ reports: Report[] }>(`/api/reports?status=${encodeURIComponent(status)}`).then(
      (r) => r.reports
    ),
  resolveReport: (id: string, outcome: 'reviewed' | 'dismissed') =>
    request<void>(`/api/reports/${encodeURIComponent(id)}/resolve`, {
      method: 'POST',
      body: JSON.stringify({ outcome }),
    }),
  getAnnouncements: (mahallaId?: string) =>
    request<{ announcements: Announcement[] }>(
      `/api/announcements${mahallaId ? `?mahallaId=${encodeURIComponent(mahallaId)}` : ''}`
    ).then((r) => r.announcements),
  deleteAnnouncement: (mahallaId: string, id: string) =>
    request<void>(
      `/api/announcements/${encodeURIComponent(mahallaId)}/${encodeURIComponent(id)}`,
      { method: 'DELETE' }
    ),
  getEvents: (mahallaId?: string) =>
    request<{ events: MahallaEvent[] }>(
      `/api/events${mahallaId ? `?mahallaId=${encodeURIComponent(mahallaId)}` : ''}`
    ).then((r) => r.events),
  deleteEvent: (mahallaId: string, id: string) =>
    request<void>(`/api/events/${encodeURIComponent(mahallaId)}/${encodeURIComponent(id)}`, {
      method: 'DELETE',
    }),
  getRequests: (status?: string, mahallaId?: string) => {
    const params = new URLSearchParams();
    if (status) params.set('status', status);
    if (mahallaId) params.set('mahallaId', mahallaId);
    const qs = params.toString();
    return request<{ requests: MurojaatRequest[] }>(`/api/requests${qs ? `?${qs}` : ''}`).then(
      (r) => r.requests
    );
  },
  updateRequestStatus: (
    mahallaId: string,
    id: string,
    status: 'yangi' | 'jarayonda' | 'yakunlandi'
  ) =>
    request<{ request: MurojaatRequest }>(
      `/api/requests/${encodeURIComponent(mahallaId)}/${encodeURIComponent(id)}/status`,
      { method: 'POST', body: JSON.stringify({ status }) }
    ),
  getPolls: (mahallaId?: string) =>
    request<{ polls: Poll[] }>(
      `/api/polls${mahallaId ? `?mahallaId=${encodeURIComponent(mahallaId)}` : ''}`
    ).then((r) => r.polls),
  getServiceAds: (mahallaId?: string) =>
    request<{ serviceAds: ServiceAd[] }>(
      `/api/service-ads${mahallaId ? `?mahallaId=${encodeURIComponent(mahallaId)}` : ''}`
    ).then((r) => r.serviceAds),
  deleteServiceAd: (mahallaId: string, id: string) =>
    request<void>(
      `/api/service-ads/${encodeURIComponent(mahallaId)}/${encodeURIComponent(id)}`,
      { method: 'DELETE' }
    ),
  searchUsers: (search: string) =>
    request<{ users: AdminUser[]; searchedField: string }>(
      `/api/users?search=${encodeURIComponent(search)}`
    ),
  updateUserRole: (uid: string, role: 'citizen' | 'staff' | 'rais' | 'superAdmin') =>
    request<{ user: AdminUser }>(`/api/users/${encodeURIComponent(uid)}/role`, {
      method: 'POST',
      body: JSON.stringify({ role }),
    }),
};

export function currentUserEmail(): string | null {
  return auth.currentUser?.email ?? null;
}
