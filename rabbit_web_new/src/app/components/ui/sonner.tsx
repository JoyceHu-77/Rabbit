"use client";

import { useTheme } from "next-themes";
import { Toaster as Sonner, ToasterProps } from "sonner";

const Toaster = ({ ...props }: ToasterProps) => {
  const { theme = "system" } = useTheme();

  return (
    <Sonner
      theme="light"
      className="toaster group"
      style={
        {
          "--normal-bg": "var(--popover)",
          "--normal-text": "var(--popover-foreground)",
          "--normal-border": "var(--border)",
        } as React.CSSProperties
      }
      toastOptions={{
        classNames: {
          success: "!bg-green-50 !text-green-800 !border !border-green-200",
          error: "!bg-red-50 !text-red-800 !border !border-red-200",
          info: "!bg-blue-50 !text-blue-800 !border !border-blue-200",
          warning: "!bg-orange-50 !text-orange-800 !border !border-orange-200",
        },
      }}
      {...props}
    />
  );
};

export { Toaster };
