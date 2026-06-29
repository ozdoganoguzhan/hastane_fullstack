import * as React from "react";

import { CheckIcon, InfoIcon } from "@/components/icons";

type Tone = "danger" | "success" | "info";

const toneStyles: Record<Tone, string> = {
  danger: "bg-danger/10 text-danger",
  success: "bg-success/10 text-success",
  info: "bg-accent/10 text-accent",
};

export function StatusBanner({
  tone = "info",
  children,
}: {
  tone?: Tone;
  children: React.ReactNode;
}) {
  const Icon = tone === "success" ? CheckIcon : InfoIcon;

  return (
    <div className={`flex items-start gap-2 rounded-xl px-3 py-2.5 text-sm ${toneStyles[tone]}`}>
      <Icon className="mt-0.5 shrink-0" size={16} />
      <span>{children}</span>
    </div>
  );
}
