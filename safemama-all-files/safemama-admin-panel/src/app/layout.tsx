import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { AuthenticatedLayout } from "@/components/layout/authenticated-layout";
import { Toaster } from "@/components/ui/sonner";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "SafeMama Admin Panel",
  description: "Admin dashboard for SafeMama pregnancy app",
  icons: {
    icon: "/favicon.ico",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${inter.variable} font-sans antialiased`}>
        <AuthenticatedLayout>{children}</AuthenticatedLayout>
        <Toaster position="top-right" />
      </body>
    </html>
  );
}
