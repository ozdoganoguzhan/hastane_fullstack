"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { Button, Card, Input, Label, TextField } from "@heroui/react";

import { ApiError } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { HeartPulseIcon } from "@/components/icons";
import { StatusBanner } from "@/components/status-banner";

export default function LoginPage() {
  const router = useRouter();
  const { login, ready, isAuthenticated } = useAuth();

  const [username, setUsername] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [error, setError] = React.useState<string | null>(null);
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (ready && isAuthenticated) router.replace("/dashboard");
  }, [ready, isAuthenticated, router]);

  async function handleSubmit() {
    setError(null);

    if (!username.trim() || !password) {
      setError("Kullanıcı adı ve şifre zorunludur.");

      return;
    }

    setSubmitting(true);
    try {
      await login(username.trim(), password);
      router.replace("/dashboard");
    } catch (e) {
      setError(
        e instanceof ApiError
          ? e.message
          : "Giriş yapılamadı. Sunucuya ulaşılamıyor olabilir.",
      );
      setSubmitting(false);
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-surface-secondary p-6">
      <Card className="w-full max-w-md">
        <Card.Header className="flex flex-col items-center gap-3 pt-8">
          <div className="flex size-14 items-center justify-center rounded-2xl bg-brand text-brand-foreground">
            <HeartPulseIcon size={28} />
          </div>
          <div className="text-center">
            <Card.Title className="text-xl">Hastane Menü Paneli</Card.Title>
            <Card.Description>Yönetim paneline giriş yapın</Card.Description>
          </div>
        </Card.Header>

        <Card.Content className="flex flex-col gap-4">
          {error && <StatusBanner tone="danger">{error}</StatusBanner>}

          <TextField value={username} variant="secondary" onChange={setUsername}>
            <Label>Kullanıcı Adı</Label>
            <Input autoFocus placeholder="admin" />
          </TextField>

          <TextField
            type="password"
            value={password}
            variant="secondary"
            onChange={setPassword}
          >
            <Label>Şifre</Label>
            <Input
              placeholder="••••••••"
              onKeyDown={(e) => {
                if (e.key === "Enter") handleSubmit();
              }}
            />
          </TextField>
        </Card.Content>

        <Card.Footer>
          <Button
            fullWidth
            isPending={submitting}
            variant="primary"
            onPress={handleSubmit}
          >
            Giriş Yap
          </Button>
        </Card.Footer>
      </Card>
    </main>
  );
}
