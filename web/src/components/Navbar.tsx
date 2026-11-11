"use client";

import React from "react";
import { Download, Github, Globe } from "lucide-react";
import { Language, translations } from "@/lib/translations";

interface NavbarProps {
  lang: Language;
  onToggleLang: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({ lang, onToggleLang }) => {
  const t = translations[lang].nav;

  return (
    <header className="sticky top-0 z-50 w-full backdrop-blur-xl bg-[#08090c]/80 border-b border-white/[0.08]">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
        {/* Brand Logo */}
        <a href="#" className="flex items-center gap-2.5 group">
          <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center shadow-lg shadow-blue-500/25 group-hover:scale-105 transition-transform">
            <span className="text-white font-bold text-base">✦</span>
          </div>
          <div className="flex flex-col">
            <span className="font-bold text-base tracking-tight text-white group-hover:text-blue-400 transition-colors">
              PopClick
            </span>
            <span className="text-[10px] text-blue-400 font-medium -mt-1 tracking-wide">
              AI AGENT
            </span>
          </div>
        </a>

        {/* Desktop Navigation */}
        <nav className="hidden md:flex items-center gap-6 text-sm text-neutral-400 font-medium">
          <a href="#features" className="hover:text-white transition-colors">
            {t.features}
          </a>
          <a href="#ai-agent" className="hover:text-white transition-colors">
            {t.aiAgent}
          </a>
          <a href="#code-math" className="hover:text-white transition-colors">
            {t.codeMath}
          </a>
          <a href="#comparison" className="hover:text-white transition-colors">
            {t.comparison}
          </a>
          <a href="#faq" className="hover:text-white transition-colors">
            {t.faq}
          </a>
        </nav>

        {/* Action Controls */}
        <div className="flex items-center gap-3">
          {/* Language Switcher */}
          <button
            onClick={onToggleLang}
            className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs font-medium text-neutral-300 hover:text-white bg-white/[0.05] hover:bg-white/[0.1] border border-white/[0.08] transition-all"
            title="Switch Language / 切换语言"
          >
            <Globe className="w-3.5 h-3.5 text-blue-400" />
            <span>{lang === "en" ? "中文" : "English"}</span>
          </button>

          {/* GitHub Star */}
          <a
            href="https://github.com/bin158/popclick"
            target="_blank"
            rel="noopener noreferrer"
            className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium text-neutral-300 hover:text-white bg-white/[0.05] hover:bg-white/[0.1] border border-white/[0.08] transition-all"
          >
            <Github className="w-3.5 h-3.5" />
            <span>GitHub</span>
          </a>

          {/* Download Button */}
          <a
            href="/downloads/PopClick.dmg"
            download
            className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg text-xs font-semibold text-white bg-blue-600 hover:bg-blue-500 shadow-md shadow-blue-600/30 transition-all hover:scale-[1.02] active:scale-[0.98]"
          >
            <Download className="w-3.5 h-3.5" />
            <span>{t.download}</span>
          </a>
        </div>
      </div>
    </header>
  );
};
