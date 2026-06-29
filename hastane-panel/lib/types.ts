export type AnnouncementType = "important" | "info" | "general";

export interface AuthUser {
  username: string;
  displayName: string;
  role: string;
}

export interface LoginResponse {
  token: string;
  expiresAt: string;
  user: AuthUser;
}

export interface Announcement {
  id: string;
  type: AnnouncementType;
  title: string;
  body: string;
  isPublished: boolean;
  publishDate: string;
  createdAt: string;
  updatedAt: string | null;
}

export interface SaveAnnouncement {
  type: AnnouncementType;
  title: string;
  body: string;
  isPublished: boolean;
  publishDate: string; // yyyy-MM-dd
}

export interface HospitalInfo {
  hospitalName: string;
  subtitle: string;
  description: string;
  workingHours: string;
  location: string;
  contact: string;
  updatedAt: string;
}

export type UpdateHospitalInfo = Omit<HospitalInfo, "updatedAt">;

export interface PagedResult<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

export interface AnnouncementStats {
  total: number;
  published: number;
  draft: number;
}

export const ANNOUNCEMENT_TYPES: { key: AnnouncementType; label: string }[] = [
  { key: "important", label: "Önemli" },
  { key: "info", label: "Bilgi" },
  { key: "general", label: "Genel" },
];
