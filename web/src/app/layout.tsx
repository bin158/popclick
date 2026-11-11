import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "PopClick ✦ The Ultra-Modern macOS Text Action Launcher & AI Agent",
  description: "Native macOS floating text action launcher featuring PopClick AI Agent, 100% offline KaTeX LaTeX rendering, code intelligence with LCS Diff, and zero Electron bloat.",
  keywords: ["PopClick", "macOS", "PopClick AI Agent", "Text Selection", "Mac Productivity", "KaTeX", "Code Diff", "Swift", "AppKit"],
  openGraph: {
    title: "PopClick ✦ The Modern macOS Text Action Launcher & AI Agent",
    description: "Supercharge text selection on your Mac. Instant actions, PopClick AI Agent, offline LaTeX math, and code intelligence.",
    url: "https://popclick.app",
    siteName: "PopClick",
    images: [
      {
        url: "/assets/banner.svg",
        width: 1200,
        height: 630,
        alt: "PopClick Banner",
      },
    ],
    locale: "en_US",
    type: "website",
  },
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
    <html lang="en" className="dark scroll-smooth">
      <body className="bg-[#08090c] text-white antialiased min-h-screen flex flex-col">
        {children}
      </body>
    </html>
  );
}
