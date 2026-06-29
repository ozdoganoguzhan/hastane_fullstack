import type {
  Announcement,
  AnnouncementStats,
  AuthUser,
  HospitalInfo,
  LoginResponse,
  PagedResult,
  SaveAnnouncement,
  UpdateHospitalInfo,
} from "./types";

export const BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:5080";

const TOKEN_KEY = "ozi_token";
const USER_KEY = "ozi_user";

export class ApiError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

export const tokenStore = {
  get(): string | null {
    if (typeof window === "undefined") return null;
    return window.localStorage.getItem(TOKEN_KEY);
  },
  getUser(): AuthUser | null {
    if (typeof window === "undefined") return null;
    const raw = window.localStorage.getItem(USER_KEY);
    return raw ? (JSON.parse(raw) as AuthUser) : null;
  },
  set(token: string, user: AuthUser) {
    window.localStorage.setItem(TOKEN_KEY, token);
    window.localStorage.setItem(USER_KEY, JSON.stringify(user));
  },
  clear() {
    if (typeof window === "undefined") return;
    window.localStorage.removeItem(TOKEN_KEY);
    window.localStorage.removeItem(USER_KEY);
  },
};

async function request<T>(
  path: string,
  options: RequestInit & { auth?: boolean } = {},
): Promise<T> {
  const { auth = true, headers, ...rest } = options;
  const token = auth ? tokenStore.get() : null;

  const res = await fetch(`${BASE_URL}${path}`, {
    ...rest,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...headers,
    },
  });

  if (res.status === 401 && auth) {
    tokenStore.clear();
    throw new ApiError("Oturum süresi doldu. Lütfen tekrar giriş yapın.", 401);
  }

  if (res.status === 204) return undefined as T;

  const data = await res.json().catch(() => null);

  if (!res.ok) {
    const message = (data && (data.message as string)) || "İstek başarısız oldu.";
    throw new ApiError(message, res.status);
  }

  return data as T;
}

export const api = {
  login: (username: string, password: string) =>
    request<LoginResponse>("/auth/login", {
      method: "POST",
      auth: false,
      body: JSON.stringify({ username, password }),
    }),

  listAnnouncements: (page = 1, pageSize = 10) =>
    request<PagedResult<Announcement>>(
      `/admin/announcements?page=${page}&pageSize=${pageSize}`,
    ),

  announcementStats: () => request<AnnouncementStats>("/admin/announcements/stats"),

  createAnnouncement: (payload: SaveAnnouncement) =>
    request<Announcement>("/admin/announcements", {
      method: "POST",
      body: JSON.stringify(payload),
    }),

  updateAnnouncement: (id: string, payload: SaveAnnouncement) =>
    request<Announcement>(`/admin/announcements/${id}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    }),

  deleteAnnouncement: (id: string) =>
    request<void>(`/admin/announcements/${id}`, { method: "DELETE" }),

  getHospitalInfo: () => request<HospitalInfo>("/admin/hospital-info"),

  updateHospitalInfo: (payload: UpdateHospitalInfo) =>
    request<HospitalInfo>("/admin/hospital-info", {
      method: "PUT",
      body: JSON.stringify(payload),
    }),
};
