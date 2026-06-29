"use client";

import * as React from "react";
import { Button, Card, Input, Label, Switch, TextArea, TextField } from "@heroui/react";

import { ANNOUNCEMENT_TYPES } from "@/lib/types";
import type { Announcement, AnnouncementType, SaveAnnouncement } from "@/lib/types";
import { StatusBanner } from "@/components/status-banner";

function todayIso() {
  return new Date().toISOString().slice(0, 10);
}

export function AnnouncementEditor({
  initial,
  onCancel,
  onSubmit,
}: {
  initial: Announcement | null;
  onCancel: () => void;
  onSubmit: (payload: SaveAnnouncement) => Promise<void>;
}) {
  const [type, setType] = React.useState<AnnouncementType>(initial?.type ?? "info");
  const [title, setTitle] = React.useState(initial?.title ?? "");
  const [body, setBody] = React.useState(initial?.body ?? "");
  const [publishDate, setPublishDate] = React.useState(
    initial?.publishDate ? initial.publishDate.slice(0, 10) : todayIso(),
  );
  const [isPublished, setIsPublished] = React.useState(initial?.isPublished ?? true);
  const [error, setError] = React.useState<string | null>(null);
  const [saving, setSaving] = React.useState(false);

  async function submit() {
    setError(null);

    if (!title.trim()) {
      setError("Başlık zorunludur.");

      return;
    }
    if (!body.trim()) {
      setError("İçerik zorunludur.");

      return;
    }

    setSaving(true);
    try {
      await onSubmit({
        type,
        title: title.trim(),
        body: body.trim(),
        isPublished,
        publishDate,
      });
    } catch (e) {
      setError(e instanceof Error ? e.message : "Duyuru kaydedilemedi.");
      setSaving(false);
    }
  }

  return (
    <Card className="mb-6">
      <Card.Header>
        <Card.Title>{initial ? "Duyuruyu Düzenle" : "Yeni Duyuru"}</Card.Title>
      </Card.Header>

      <Card.Content className="flex flex-col gap-4">
        {error && <StatusBanner tone="danger">{error}</StatusBanner>}

        <div className="flex flex-col gap-1.5">
          <span className="text-sm font-medium text-foreground">Tür</span>
          <div className="flex gap-2">
            {ANNOUNCEMENT_TYPES.map(({ key, label }) => (
              <Button
                key={key}
                size="sm"
                variant={type === key ? "primary" : "outline"}
                onPress={() => setType(key)}
              >
                {label}
              </Button>
            ))}
          </div>
        </div>

        <TextField value={title} variant="secondary" onChange={setTitle}>
          <Label>Başlık</Label>
          <Input placeholder="Duyuru başlığı" />
        </TextField>

        <TextField value={body} variant="secondary" onChange={setBody}>
          <Label>İçerik</Label>
          <TextArea placeholder="Duyuru metni" rows={5} />
        </TextField>

        <div className="flex flex-wrap items-center gap-6">
          <TextField
            className="w-48"
            value={publishDate}
            variant="secondary"
            onChange={setPublishDate}
          >
            <Label>Yayın Tarihi</Label>
            <Input type="date" />
          </TextField>

          <Switch isSelected={isPublished} onChange={setIsPublished}>
            <Switch.Control>
              <Switch.Thumb />
            </Switch.Control>
            <Switch.Content>
              <Label className="text-sm">Yayında</Label>
            </Switch.Content>
          </Switch>
        </div>
      </Card.Content>

      <Card.Footer className="flex justify-end gap-2">
        <Button isDisabled={saving} variant="outline" onPress={onCancel}>
          Vazgeç
        </Button>
        <Button isPending={saving} variant="primary" onPress={submit}>
          Kaydet
        </Button>
      </Card.Footer>
    </Card>
  );
}
