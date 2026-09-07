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

export interface StatsHistoryEntry {
  totalMahallas: number;
  totalUsers: number;
  totalActiveRequests: number;
  totalPendingPremium: number;
  recordedAt: string;
}

export interface MahallaDetail extends Mahalla {
  rais: { id: string; [key: string]: unknown } | null;
  raisCount: number;
  memberCount: number;
  requestsByStatus: { yangi: number; jarayonda: number; yakunlandi: number };
  counts: {
    announcements: number;
    events: number;
    polls: number;
    serviceAds: number;
    services: number;
  };
}

export interface AuditLogEntry {
  actorUid: string;
  action: string;
  details?: Record<string, unknown> | string | null;
  timestamp: string;
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
  title?: string;
  description?: string;
  linkUrl?: string;
  order: number;
  attribution?: string;
  createdAt?: string;
  [key: string]: unknown;
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

export interface LocalService {
  id: string;
  mahallaId: string;
  name: string;
  category: string;
  phone: string;
  description?: string;
  authorUid?: string;
  createdAt?: string;
  [key: string]: unknown;
}

export const SERVICE_CATEGORIES = [
  { value: 'santexnik', label: 'Santexnik' },
  { value: 'elektrik', label: 'Elektrik' },
  { value: 'duradgor', label: 'Duradgor' },
  { value: 'tozalash', label: 'Tozalash' },
  { value: 'qurilish', label: 'Qurilish' },
  { value: 'boshqa', label: 'Boshqa' },
] as const;

export const ANNOUNCEMENT_CATEGORIES = [
  { value: 'kommunal', label: 'Kommunal' },
  { value: 'xavfsizlik', label: 'Xavfsizlik' },
  { value: 'umumiy', label: 'Umumiy' },
] as const;

export const api = {
  getStats: () => request<Stats>('/api/stats'),
  getStatsHistory: (days = 30) =>
    request<{ history: StatsHistoryEntry[] }>(`/api/stats/history?days=${days}`).then(
      (r) => r.history
    ),
  getMahallas: () => request<{ mahallas: Mahalla[] }>('/api/mahallas').then((r) => r.mahallas),
  createMahalla: (data: { name: string; district?: string }) =>
    request<{ mahalla: Mahalla; joinCode: string }>('/api/mahallas', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  getMahallaDetail: (id: string) =>
    request<{ mahalla: MahallaDetail }>(
      `/api/mahallas/${encodeURIComponent(id)}/detail`
    ).then((r) => r.mahalla),
  getAuditLog: (limit = 50) =>
    request<{ auditLog: AuditLogEntry[] }>(`/api/audit-log?limit=${limit}`).then(
      (r) => r.auditLog
    ),
  getPremiumRequests: (status = 'pending') =>
    request<{ premiumRequests: PremiumRequest[] }>(
      `/api/premium-requests?status=${encodeURIComponent(status)}`
    ).then((r) => r.premiumRequests),
  approvePremiumRequest: (id: string) =>
    request<void>(`/api/premium-requests/${encodeURIComponent(id)}/approve`, { method: 'POST' }),
  rejectPremiumRequest: (id: string) =>
    request<void>(`/api/premium-requests/${encodeURIComponent(id)}/reject`, { method: 'POST' }),
  getBanners: () => request<{ banners: Banner[] }>('/api/banners').then((r) => r.banners),
  createBanner: (data: {
    imageUrl: string;
    title: string;
    description: string;
    linkUrl?: string;
    order: number;
    attribution?: string;
  }) => request<{ banner: Banner }>('/api/banners', { method: 'POST', body: JSON.stringify(data) }),
  updateBanner: (
    id: string,
    data: Partial<{
      imageUrl: string;
      title: string;
      description: string;
      linkUrl: string;
      order: number;
      attribution: string;
    }>
  ) =>
    request<{ banner: Banner }>(`/api/banners/${encodeURIComponent(id)}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    }),
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
  createAnnouncement: (data: {
    mahallaId: string;
    title: string;
    body: string;
    category: string;
    imageUrl?: string;
  }) =>
    request<{ announcement: Announcement }>('/api/announcements', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  updateAnnouncement: (
    mahallaId: string,
    id: string,
    data: Partial<{ title: string; body: string; category: string; imageUrl: string }>
  ) =>
    request<{ announcement: Announcement }>(
      `/api/announcements/${encodeURIComponent(mahallaId)}/${encodeURIComponent(id)}`,
      { method: 'PATCH', body: JSON.stringify(data) }
    ),
  deleteAnnouncement: (mahallaId: string, id: string) =>
    request<void>(
      `/api/announcements/${encodeURIComponent(mahallaId)}/${encodeURIComponent(id)}`,
      { method: 'DELETE' }
    ),
  getEvents: (mahallaId?: string) =>
    request<{ events: MahallaEvent[] }>(
      `/api/events${mahallaId ? `?mahallaId=${encodeURIComponent(mahallaId)}` : ''}`
    ).then((r) => r.events),
  createEvent: (data: { mahallaId: string; title: string; dateTime: string; location: string }) =>
    request<{ event: MahallaEvent }>('/api/events', { method: 'POST', body: JSON.stringify(data) }),
  updateEvent: (
    mahallaId: string,
    id: string,
    data: Partial<{ title: string; dateTime: string; location: string }>
  ) =>
    request<{ event: MahallaEvent }>(
      `/api/events/${encodeURIComponent(mahallaId)}/${encodeURIComponent(id)}`,
      { method: 'PATCH', body: JSON.stringify(data) }
    ),
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
  createPoll: (data: {
    mahallaId: string;
    question: string;
    options: string[];
    allowMultiple?: boolean;
    isAnonymous?: boolean;
    closesAt?: string | null;
  }) => request<{ poll: Poll }>('/api/polls', { method: 'POST', body: JSON.stringify(data) }),
  updatePoll: (
    mahallaId: string,
    id: string,
    data: Partial<{
      question: string;
      options: string[];
      allowMultiple: boolean;
      isAnonymous: boolean;
      closesAt: string | null;
    }>
  ) =>
    request<{ poll: Poll }>(`/api/polls/${encodeURIComponent(mahallaId)}/${encodeURIComponent(id)}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    }),
  deletePoll: (mahallaId: string, id: string) =>
    request<void>(`/api/polls/${encodeURIComponent(mahallaId)}/${encodeURIComponent(id)}`, {
      method: 'DELETE',
    }),
  getServiceAds: (mahallaId?: string) =>
    request<{ serviceAds: ServiceAd[] }>(
      `/api/service-ads${mahallaId ? `?mahallaId=${encodeURIComponent(mahallaId)}` : ''}`
    ).then((r) => r.serviceAds),
  createServiceAd: (data: {
    mahallaId: string;
    title: string;
    description: string;
    phone: string;
    ownerName: string;
    durationDays?: number;
  }) =>
    request<{ serviceAd: ServiceAd }>('/api/service-ads', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  updateServiceAd: (
    mahallaId: string,
    id: string,
    data: Partial<{
      title: string;
      description: string;
      phone: string;
      ownerName: string;
      durationDays: number;
      extendFromCurrent: boolean;
    }>
  ) =>
    request<{ serviceAd: ServiceAd }>(
      `/api/service-ads/${encodeURIComponent(mahallaId)}/${encodeURIComponent(id)}`,
      { method: 'PATCH', body: JSON.stringify(data) }
    ),
  deleteServiceAd: (mahallaId: string, id: string) =>
    request<void>(
      `/api/service-ads/${encodeURIComponent(mahallaId)}/${encodeURIComponent(id)}`,
      { method: 'DELETE' }
    ),
  getServices: (mahallaId?: string) =>
    request<{ services: LocalService[] }>(
      `/api/services${mahallaId ? `?mahallaId=${encodeURIComponent(mahallaId)}` : ''}`
    ).then((r) => r.services),
  createService: (data: {
    mahallaId: string;
    name: string;
    category: string;
    phone: string;
    description: string;
  }) =>
    request<{ service: LocalService }>('/api/services', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  updateService: (
    mahallaId: string,
    id: string,
    data: Partial<{ name: string; category: string; phone: string; description: string }>
  ) =>
    request<{ service: LocalService }>(
      `/api/services/${encodeURIComponent(mahallaId)}/${encodeURIComponent(id)}`,
      { method: 'PATCH', body: JSON.stringify(data) }
    ),
  deleteService: (mahallaId: string, id: string) =>
    request<void>(`/api/services/${encodeURIComponent(mahallaId)}/${encodeURIComponent(id)}`, {
      method: 'DELETE',
    }),
  searchUsers: (search: string) =>
    request<{ users: AdminUser[]; searchedField: string }>(
      `/api/users?search=${encodeURIComponent(search)}`
    ),
  updateUserRole: (uid: string, role: 'citizen' | 'staff' | 'rais' | 'superAdmin') =>
    request<{ user: AdminUser }>(`/api/users/${encodeURIComponent(uid)}/role`, {
      method: 'POST',
      body: JSON.stringify({ role }),
    }),
  grantPremium: (uid: string, months = 1) =>
    request<{ user: AdminUser }>(`/api/users/${encodeURIComponent(uid)}/premium/grant`, {
      method: 'POST',
      body: JSON.stringify({ months }),
    }),
  revokePremium: (uid: string) =>
    request<{ user: AdminUser }>(`/api/users/${encodeURIComponent(uid)}/premium/revoke`, {
      method: 'POST',
    }),
  getAssistantConfig: () =>
    request<{ geminiApiKeyMasked: string | null; hasKey: boolean }>('/api/assistant-config'),
  setAssistantGeminiKey: (geminiApiKey: string) =>
    request<void>('/api/assistant-config', {
      method: 'POST',
      body: JSON.stringify({ geminiApiKey }),
    }),
};

export function currentUserEmail(): string | null {
  return auth.currentUser?.email ?? null;
}
