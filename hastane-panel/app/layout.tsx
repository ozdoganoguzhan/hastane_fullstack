import "@/styles/globals.css";
import { Metadata, Viewport } from "next";
import clsx from "clsx";

import { Providers } from "./providers";

import { fontSans } from "@/config/fonts";

export const metadata: Metadata = {
  title: {
    default: "Hastane Menü Paneli",
    template: "%s · Hastane Menü Paneli",
  },
  description: "Eskişehir Şehir Hastanesi yemekhane yönetim paneli",
  icons: { icon: "/favicon.ico" },
};

export const viewport: Viewport = {
  themeColor: "#c8102e",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html suppressHydrationWarning lang="tr">
      <head />
      <body
        className={clsx(
          "min-h-screen bg-background font-sans text-foreground antialiased",
          fontSans.variable,
        )}
      >
        <Providers
          themeProps={{ attribute: "class", defaultTheme: "light", enableSystem: true }}
        >
          {children}
        </Providers>
      </body>
    </html>
  );
}
