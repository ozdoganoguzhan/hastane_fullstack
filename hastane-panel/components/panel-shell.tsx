"use client";

import * as React from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useTheme } from "next-themes";
import { Button } from "@heroui/react";

import { useAuth } from "@/lib/auth";
import {
  ChevronLeftIcon,
  ChevronRightIcon,
  DashboardIcon,
  HeartPulseIcon,
  HospitalIcon,
  LogoutIcon,
  MegaphoneIcon,
  MenuIcon,
  MoonIcon,
  SunIcon,
  UserIcon,
} from "@/components/icons";

type IconType = React.ComponentType<{ size?: number; className?: string }>;

const NAV: { href: string; label: string; icon: IconType }[] = [
  { href: "/dashboard", label: "Genel Bakış", icon: DashboardIcon },
  { href: "/duyurular", label: "Duyurular", icon: MegaphoneIcon },
  { href: "/hastane-bilgisi", label: "Hastane Bilgisi", icon: HospitalIcon },
];

const COLLAPSE_KEY = "ozi_sidebar_collapsed";

function HoverTip({ label }: { label: string }) {
  return (
    <span className="pointer-events-none absolute left-full top-1/2 z-50 ml-2 -translate-y-1/2 whitespace-nowrap rounded-lg border border-border bg-overlay px-2.5 py-1.5 text-xs font-medium text-foreground opacity-0 shadow-overlay transition-opacity duration-100 group-hover:opacity-100">
      {label}
    </span>
  );
}

export function PanelShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { user, logout } = useAuth();
  const { theme, setTheme } = useTheme();

  const [mobileOpen, setMobileOpen] = React.useState(false);
  const [collapsed, setCollapsed] = React.useState(false);
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
    setCollapsed(window.localStorage.getItem(COLLAPSE_KEY) === "1");
  }, []);

  function toggleCollapsed() {
    setCollapsed((c) => {
      const next = !c;

      window.localStorage.setItem(COLLAPSE_KEY, next ? "1" : "0");

      return next;
    });
  }

  function handleLogout() {
    logout();
    router.replace("/login");
  }

  const isDark = mounted && theme === "dark";

  function rowClass(isCollapsed: boolean, active = false) {
    const base = "group relative flex h-10 items-center rounded-xl text-sm transition-colors";
    const shape = isCollapsed ? "justify-center" : "gap-3 px-3";
    const state = active
      ? "bg-surface-secondary font-medium text-foreground shadow-surface"
      : "text-muted hover:bg-surface-secondary/70 hover:text-foreground";

    return `${base} ${shape} ${state}`;
  }

  function renderSidebar(isCollapsed: boolean, onNavigate?: () => void) {
    return (
      <div
        className={`flex h-full flex-col border-r border-border bg-background py-4 ${
          isCollapsed ? "w-16 px-2" : "w-64 px-3"
        }`}
      >
        <div className={`mb-5 flex items-center px-1 ${isCollapsed ? "justify-center" : "gap-2.5"}`}>
          <div className="flex size-9 shrink-0 items-center justify-center rounded-xl bg-brand text-brand-foreground">
            <HeartPulseIcon size={20} />
          </div>
          {!isCollapsed && (
            <div className="leading-tight">
              <p className="text-sm font-semibold text-foreground">Hastane Menü</p>
              <p className="text-xs text-muted">Yönetim Paneli</p>
            </div>
          )}
        </div>

        <nav className="flex flex-col gap-1">
          {NAV.map(({ href, label, icon: Icon }) => {
            const active = pathname === href || pathname.startsWith(`${href}/`);

            return (
              <Link
                key={href}
                className={rowClass(isCollapsed, active)}
                href={href}
                onClick={onNavigate}
              >
                <Icon className="shrink-0" size={18} />
                {!isCollapsed && <span className="truncate">{label}</span>}
                {isCollapsed && <HoverTip label={label} />}
              </Link>
            );
          })}
        </nav>

        <div className="mt-auto flex flex-col gap-1.5">
          {!isCollapsed && (
            <div className="flex items-center gap-2.5 rounded-xl px-2 py-1.5">
              <div className="flex size-8 shrink-0 items-center justify-center rounded-full bg-surface-secondary text-muted">
                <UserIcon size={16} />
              </div>
              <div className="min-w-0 leading-tight">
                <p className="truncate text-sm font-medium text-foreground">
                  {user?.displayName ?? "Yönetici"}
                </p>
                <p className="truncate text-xs text-muted">@{user?.username ?? "admin"}</p>
              </div>
            </div>
          )}

          <button
            className={rowClass(isCollapsed)}
            type="button"
            onClick={() => setTheme(isDark ? "light" : "dark")}
          >
            {isDark ? <SunIcon size={18} /> : <MoonIcon size={18} />}
            {!isCollapsed && <span>{isDark ? "Açık Tema" : "Koyu Tema"}</span>}
            {isCollapsed && <HoverTip label={isDark ? "Açık Tema" : "Koyu Tema"} />}
          </button>

          <button
            className={`group relative flex h-10 items-center rounded-xl text-sm text-muted transition-colors hover:bg-danger/10 hover:text-danger ${
              isCollapsed ? "justify-center" : "gap-3 px-3"
            }`}
            type="button"
            onClick={handleLogout}
          >
            <LogoutIcon size={18} />
            {!isCollapsed && <span>Çıkış Yap</span>}
            {isCollapsed && <HoverTip label="Çıkış Yap" />}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-screen bg-background">
      {/* Masaüstü sidebar (daraltılabilir) */}
      <aside className="relative hidden shrink-0 md:block">
        {renderSidebar(collapsed)}
        <button
          aria-label={collapsed ? "Menüyü genişlet" : "Menüyü daralt"}
          className="absolute -right-3 top-6 z-20 flex size-6 items-center justify-center rounded-full border border-border bg-background text-muted shadow-surface transition-colors hover:text-foreground"
          type="button"
          onClick={toggleCollapsed}
        >
          {collapsed ? <ChevronRightIcon size={14} /> : <ChevronLeftIcon size={14} />}
        </button>
      </aside>

      {/* Mobil çekmece */}
      {mobileOpen && (
        <div className="fixed inset-0 z-50 md:hidden">
          <button
            aria-label="Menüyü kapat"
            className="absolute inset-0 bg-black/50"
            type="button"
            onClick={() => setMobileOpen(false)}
          />
          <div className="absolute inset-y-0 left-0 shadow-overlay">
            {renderSidebar(false, () => setMobileOpen(false))}
          </div>
        </div>
      )}

      {/* İçerik */}
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex h-14 shrink-0 items-center gap-3 border-b border-border bg-background px-4 md:hidden">
          <Button aria-label="Menü" isIconOnly variant="ghost" onPress={() => setMobileOpen(true)}>
            <MenuIcon size={20} />
          </Button>
          <span className="text-sm font-semibold text-foreground">Hastane Menü Paneli</span>
        </header>

        <main className="flex-1 overflow-y-auto">
          <div className="mx-auto w-full max-w-5xl px-4 pb-12 pt-8 md:px-8">{children}</div>
        </main>
      </div>
    </div>
  );
}
