"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { Button, Card, Input, Label, Spinner, TextArea, TextField } from "@heroui/react";

import { api, ApiError } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import type { UpdateHospitalInfo } from "@/lib/types";
import { PageHeader } from "@/components/page-header";
import { StatusBanner } from "@/components/status-banner";

const EMPTY: UpdateHospitalInfo = {
  hospitalName: "",
  subtitle: "",
  description: "",
  workingHours: "",
  location: "",
  contact: "",
};

export default function HospitalInfoPage() {
  const router = useRouter();
  const { logout } = useAuth();

  const [form, setForm] = React.useState<UpdateHospitalInfo | null>(null);
  const [error, setError] = React.useState<string | null>(null);
  const [notice, setNotice] = React.useState<string | null>(null);
  const [saving, setSaving] = React.useState(false);

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

  React.useEffect(() => {
    (async () => {
      try {
        const info = await api.getHospitalInfo();

        setForm({
          hospitalName: info.hospitalName,
          subtitle: info.subtitle,
          description: info.description,
          workingHours: info.workingHours,
          location: info.location,
          contact: info.contact,
        });
      } catch (e) {
        if (!handleAuthError(e)) {
          setForm(EMPTY);
          setError(e instanceof Error ? e.message : "Hastane bilgisi yüklenemedi.");
        }
      }
    })();
  }, [handleAuthError]);

  function update<K extends keyof UpdateHospitalInfo>(key: K, value: string) {
    setForm((prev) => (prev ? { ...prev, [key]: value } : prev));
  }

  async function handleSave() {
    if (!form) return;
    setError(null);
    setNotice(null);

    if (!form.hospitalName.trim()) {
      setError("Hastane adı zorunludur.");

      return;
    }

    setSaving(true);
    try {
      await api.updateHospitalInfo(form);
      setNotice("Hastane bilgisi kaydedildi.");
    } catch (e) {
      if (!handleAuthError(e)) setError(e instanceof Error ? e.message : "Kaydedilemedi.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <>
      <PageHeader
        description="Mobil uygulamanın “Bilgi” sayfasında gösterilen yemekhane bilgileri."
        title="Hastane Bilgisi"
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

      {form === null ? (
        <div className="flex justify-center py-16">
          <Spinner />
        </div>
      ) : (
        <Card>
          <Card.Content className="flex flex-col gap-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <TextField
                value={form.hospitalName}
                variant="secondary"
                onChange={(v) => update("hospitalName", v)}
              >
                <Label>Hastane Adı</Label>
                <Input placeholder="Eskişehir Şehir Hastanesi" />
              </TextField>

              <TextField
                value={form.subtitle}
                variant="secondary"
                onChange={(v) => update("subtitle", v)}
              >
                <Label>Alt Başlık</Label>
                <Input placeholder="Yemekhane Menü Sistemi" />
              </TextField>
            </div>

            <TextField
              value={form.description}
              variant="secondary"
              onChange={(v) => update("description", v)}
            >
              <Label>Açıklama</Label>
              <TextArea placeholder="Yemekhane hakkında kısa açıklama" rows={3} />
            </TextField>

            <div className="grid gap-4 sm:grid-cols-2">
              <TextField
                value={form.workingHours}
                variant="secondary"
                onChange={(v) => update("workingHours", v)}
              >
                <Label>Çalışma Saatleri</Label>
                <Input placeholder="Pzt-Cum: 11:30 - 13:30 | 17:30 - 19:00" />
              </TextField>

              <TextField
                value={form.contact}
                variant="secondary"
                onChange={(v) => update("contact", v)}
              >
                <Label>İletişim</Label>
                <Input placeholder="Dahili: 4500 | Mutfak Şefi: 4501" />
              </TextField>
            </div>

            <TextField
              value={form.location}
              variant="secondary"
              onChange={(v) => update("location", v)}
            >
              <Label>Konum</Label>
              <Input placeholder="B Blok, Zemin Kat, Yemekhane Salonu" />
            </TextField>
          </Card.Content>

          <Card.Footer className="flex justify-end">
            <Button isPending={saving} variant="primary" onPress={handleSave}>
              Kaydet
            </Button>
          </Card.Footer>
        </Card>
      )}
    </>
  );
}
