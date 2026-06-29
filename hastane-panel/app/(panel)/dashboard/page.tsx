"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { Card, Spinner } from "@heroui/react";

import { api, ApiError } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import type { AnnouncementStats } from "@/lib/types";
import { PageHeader } from "@/components/page-header";
import { StatusBanner } from "@/components/status-banner";
import {
  CheckIcon,
  ChevronRightIcon,
  EditIcon,
  HospitalIcon,
  MegaphoneIcon,
} from "@/components/icons";

type Tone = "accent" | "success" | "muted";

const TONE_CLASS: Record<Tone, string> = {
  accent: "bg-accent/10 text-accent",
  success: "bg-success/10 text-success",
  muted: "bg-surface-secondary text-muted",
};

type IconType = React.ComponentType<{ size?: number; className?: string }>;

function StatCard({
  label,
  value,
  icon: Icon,
  tone,
}: {
  label: string;
  value: number;
  icon: IconType;
  tone: Tone;
}) {
  return (
    <Card>
      <Card.Content className="flex items-center gap-4 p-5">
        <div
          className={`flex size-12 shrink-0 items-center justify-center rounded-xl ${TONE_CLASS[tone]}`}
        >
          <Icon size={22} />
        </div>
        <div className="flex flex-col">
          <span className="text-2xl font-semibold leading-none text-foreground tabular-nums">
            {value}
          </span>
          <span className="mt-1.5 text-sm text-muted">{label}</span>
        </div>
      </Card.Content>
    </Card>
  );
}

function ActionCard({
  title,
  description,
  icon: Icon,
  onPress,
}: {
  title: string;
  description: string;
  icon: IconType;
  onPress: () => void;
}) {
  return (
    <button
      className="flex w-full items-center gap-4 rounded-2xl bg-surface p-5 text-left shadow-surface transition-colors hover:bg-surface-secondary cursor-[var(--cursor-interactive)]"
      type="button"
      onClick={onPress}
    >
      <div className="flex size-11 shrink-0 items-center justify-center rounded-xl bg-brand/10 text-brand">
        <Icon size={22} />
      </div>
      <div className="min-w-0 flex-1">
        <p className="font-semibold text-foreground">{title}</p>
        <p className="text-sm text-muted">{description}</p>
      </div>
      <ChevronRightIcon className="shrink-0 text-muted" size={18} />
    </button>
  );
}

export default function DashboardPage() {
  const router = useRouter();
  const { user, logout } = useAuth();

  const [stats, setStats] = React.useState<AnnouncementStats | null>(null);
  const [error, setError] = React.useState<string | null>(null);

  React.useEffect(() => {
    (async () => {
      try {
        setStats(await api.announcementStats());
      } catch (e) {
        if (e instanceof ApiError && e.status === 401) {
          logout();
          router.replace("/login");

          return;
        }
        setStats({ total: 0, published: 0, draft: 0 });
        setError(e instanceof Error ? e.message : "Veriler yüklenemedi.");
      }
    })();
  }, [logout, router]);

  return (
    <>
      <PageHeader
        description={`Hoş geldiniz, ${user?.displayName ?? "Yönetici"}.`}
        title="Genel Bakış"
      />

      {error && (
        <div className="mb-4">
          <StatusBanner tone="danger">{error}</StatusBanner>
        </div>
      )}

      {stats === null ? (
        <div className="flex justify-center py-20">
          <Spinner />
        </div>
      ) : (
        <div className="flex flex-col gap-6">
          <div className="grid gap-4 sm:grid-cols-3">
            <StatCard icon={MegaphoneIcon} label="Toplam Duyuru" tone="accent" value={stats.total} />
            <StatCard icon={CheckIcon} label="Yayında" tone="success" value={stats.published} />
            <StatCard icon={EditIcon} label="Taslak" tone="muted" value={stats.draft} />
          </div>

          <div className="flex flex-col gap-3">
            <p className="text-sm font-medium text-muted">Yönetim</p>
            <div className="grid gap-4 sm:grid-cols-2">
              <ActionCard
                description="Duyuru ekle, düzenle veya kaldır"
                icon={MegaphoneIcon}
                title="Duyurular"
                onPress={() => router.push("/duyurular")}
              />
              <ActionCard
                description="Yemekhane bilgilerini düzenle"
                icon={HospitalIcon}
                title="Hastane Bilgisi"
                onPress={() => router.push("/hastane-bilgisi")}
              />
            </div>
          </div>
        </div>
      )}
    </>
  );
}
