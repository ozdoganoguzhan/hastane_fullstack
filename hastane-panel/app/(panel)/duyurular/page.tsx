"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { Button, Card, Chip, Spinner } from "@heroui/react";

import { api, ApiError } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import type { Announcement, AnnouncementType, PagedResult, SaveAnnouncement } from "@/lib/types";
import { PageHeader } from "@/components/page-header";
import { AnnouncementEditor } from "@/components/announcement-editor";
import { StatusBanner } from "@/components/status-banner";
import {
  ChevronLeftIcon,
  ChevronRightIcon,
  EditIcon,
  MegaphoneIcon,
  PlusIcon,
  TrashIcon,
} from "@/components/icons";

const PAGE_SIZE = 8;

const TYPE_META: Record<AnnouncementType, { label: string; color: "danger" | "accent" | "success" }> = {
  important: { label: "Önemli", color: "danger" },
  info: { label: "Bilgi", color: "accent" },
  general: { label: "Genel", color: "success" },
};

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString("tr-TR", {
    day: "2-digit",
    month: "long",
    year: "numeric",
  });
}

type EditingState = { item: Announcement | null } | null;

export default function AnnouncementsPage() {
  const router = useRouter();
  const { logout } = useAuth();

  const [data, setData] = React.useState<PagedResult<Announcement> | null>(null);
  const [error, setError] = React.useState<string | null>(null);
  const [notice, setNotice] = React.useState<string | null>(null);
  const [editing, setEditing] = React.useState<EditingState>(null);
  const [confirmId, setConfirmId] = React.useState<string | null>(null);

  const handleAuthError = React.useCallback(
    (e: unknown) => {
      if (e instanceof ApiError && e.status === 401) {
        logout();
        router.replace("/login");

        return true;
      }

      return false;
    },
    [logout, router],
  );

  const load = React.useCallback(
    async (page: number) => {
      setError(null);
      try {
        setData(await api.listAnnouncements(page, PAGE_SIZE));
      } catch (e) {
        if (!handleAuthError(e)) {
          setError(e instanceof Error ? e.message : "Duyurular yüklenemedi.");
        }
      }
    },
    [handleAuthError],
  );

  React.useEffect(() => {
    load(1);
  }, [load]);

  const totalPages = data ? Math.max(1, Math.ceil(data.total / data.pageSize)) : 1;

  async function handleSubmit(payload: SaveAnnouncement) {
    if (editing?.item) {
      await api.updateAnnouncement(editing.item.id, payload);
      setNotice("Duyuru güncellendi.");
      setEditing(null);
      await load(data?.page ?? 1);
    } else {
      await api.createAnnouncement(payload);
      setNotice("Duyuru oluşturuldu.");
      setEditing(null);
      await load(1);
    }
  }

  async function handleDelete(id: string) {
    try {
      await api.deleteAnnouncement(id);
      setConfirmId(null);
      setNotice("Duyuru silindi.");
      // Sayfadaki son kayıt silindiyse bir önceki sayfaya dön.
      const page = data && data.items.length === 1 && data.page > 1 ? data.page - 1 : (data?.page ?? 1);

      await load(page);
    } catch (e) {
      if (!handleAuthError(e)) setError(e instanceof Error ? e.message : "Duyuru silinemedi.");
    }
  }

  return (
    <>
      <PageHeader
        action={
          !editing && (
            <Button
              variant="primary"
              onPress={() => {
                setNotice(null);
                setEditing({ item: null });
              }}
            >
              <PlusIcon size={18} />
              Yeni Duyuru
            </Button>
          )
        }
        description="Mobil uygulamada gösterilen duyuruları yönetin."
        title="Duyurular"
      />

      {notice && (
        <div className="mb-4">
          <StatusBanner tone="success">{notice}</StatusBanner>
        </div>
      )}
      {error && (
        <div className="mb-4">
          <StatusBanner tone="danger">{error}</StatusBanner>
        </div>
      )}

      {editing && (
        <AnnouncementEditor
          initial={editing.item}
          onCancel={() => setEditing(null)}
          onSubmit={handleSubmit}
        />
      )}

      {data === null ? (
        <div className="flex justify-center py-16">
          <Spinner />
        </div>
      ) : data.items.length === 0 ? (
        <Card>
          <Card.Content className="flex flex-col items-center gap-2 py-14 text-center">
            <div className="flex size-12 items-center justify-center rounded-2xl bg-surface-secondary text-muted">
              <MegaphoneIcon size={24} />
            </div>
            <p className="font-medium text-foreground">Henüz duyuru yok</p>
            <p className="max-w-sm text-sm text-muted">
              &quot;Yeni Duyuru&quot; ile ilk duyurunuzu oluşturun. Yayınladıklarınız mobil
              uygulamada görünür.
            </p>
          </Card.Content>
        </Card>
      ) : (
        <>
          <div className="flex flex-col gap-3">
            {data.items.map((a) => (
              <Card key={a.id}>
                <Card.Content className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                  <div className="min-w-0">
                    <div className="mb-1.5 flex flex-wrap items-center gap-2">
                      <Chip color={TYPE_META[a.type].color} size="sm" variant="soft">
                        {TYPE_META[a.type].label}
                      </Chip>
                      {!a.isPublished && (
                        <Chip size="sm" variant="soft">
                          Taslak
                        </Chip>
                      )}
                      <span className="text-xs text-muted">{formatDate(a.publishDate)}</span>
                    </div>
                    <h3 className="font-semibold text-foreground">{a.title}</h3>
                    <p className="mt-0.5 line-clamp-2 text-sm text-muted">{a.body}</p>
                  </div>

                  <div className="flex shrink-0 gap-2">
                    {confirmId === a.id ? (
                      <>
                        <Button size="sm" variant="danger" onPress={() => handleDelete(a.id)}>
                          Sil
                        </Button>
                        <Button size="sm" variant="outline" onPress={() => setConfirmId(null)}>
                          Vazgeç
                        </Button>
                      </>
                    ) : (
                      <>
                        <Button
                          size="sm"
                          variant="ghost"
                          onPress={() => {
                            setNotice(null);
                            setEditing({ item: a });
                          }}
                        >
                          <EditIcon size={16} />
                          Düzenle
                        </Button>
                        <Button size="sm" variant="danger-soft" onPress={() => setConfirmId(a.id)}>
                          <TrashIcon size={16} />
                          Sil
                        </Button>
                      </>
                    )}
                  </div>
                </Card.Content>
              </Card>
            ))}
          </div>

          {data.total > data.pageSize && (
            <div className="mt-5 flex items-center justify-between">
              <span className="text-sm text-muted tabular-nums">
                {data.total} duyuru · Sayfa {data.page}/{totalPages}
              </span>
              <div className="flex gap-2">
                <Button
                  isDisabled={data.page <= 1}
                  size="sm"
                  variant="outline"
                  onPress={() => load(data.page - 1)}
                >
                  <ChevronLeftIcon size={16} />
                  Önceki
                </Button>
                <Button
                  isDisabled={data.page >= totalPages}
                  size="sm"
                  variant="outline"
                  onPress={() => load(data.page + 1)}
                >
                  Sonraki
                  <ChevronRightIcon size={16} />
                </Button>
              </div>
            </div>
          )}
        </>
      )}
    </>
  );
}
