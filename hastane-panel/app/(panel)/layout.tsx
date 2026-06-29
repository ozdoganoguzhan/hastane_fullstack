"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { Spinner } from "@heroui/react";

import { useAuth } from "@/lib/auth";
import { PanelShell } from "@/components/panel-shell";

export default function PanelLayout({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, ready } = useAuth();
  const router = useRouter();

  React.useEffect(() => {
    if (ready && !isAuthenticated) router.replace("/login");
  }, [ready, isAuthenticated, router]);

  if (!ready || !isAuthenticated) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background">
        <Spinner />
      </div>
    );
  }

  return <PanelShell>{children}</PanelShell>;
}
