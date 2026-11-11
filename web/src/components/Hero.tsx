"use client";

import React from "react";
import { Download, Sparkles, Terminal, ArrowRight, ShieldCheck, Cpu } from "lucide-react";
import { Language, translations } from "@/lib/translations";

interface HeroProps {
  lang: Language;
}

export const Hero: React.FC<HeroProps> = ({ lang }) => {
  const t = translations[lang].hero;

  return (
    <section className="relative pt-12 pb-20 md:pt-20 md:pb-28 overflow-hidden">
      {/* Background Glow */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[350px] bg-blue-600/15 blur-[120px] rounded-full pointer-events-none" />
      <div className="absolute top-1/3 left-1/3 w-[300px] h-[250px] bg-indigo-500/10 blur-[90px] rounded-full pointer-events-none" />

      <div className="max-w-5xl mx-auto px-4 sm:px-6 text-center relative z-10">
        {/* Version Badge */}
        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-400 text-xs font-semibold mb-8 animate-pulse-subtle">
          <Sparkles className="w-3.5 h-3.5" />
          <span>{t.badge}</span>
        </div>

        {/* Main Headline */}
        <h1 className="text-4xl sm:text-6xl md:text-7xl font-extrabold tracking-tight text-white leading-[1.12] mb-6">
          {t.titlePrefix}{" "}
          <span className="text-gradient-accent">
            {t.titleHighlight}
          </span>
        </h1>

        {/* Subtitle */}
        <p className="max-w-3xl mx-auto text-base sm:text-lg md:text-xl text-neutral-400 font-normal leading-relaxed mb-10">
          {t.subtitle}
        </p>

        {/* Download Call to Actions */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-6">
          <a
            href="/downloads/PopClick.dmg"
            download
            className="w-full sm:w-auto flex items-center justify-center gap-2.5 px-7 py-3.5 rounded-xl font-semibold text-white bg-blue-600 hover:bg-blue-500 shadow-xl shadow-blue-600/30 transition-all hover:scale-[1.02] active:scale-[0.98] group"
          >
            <Download className="w-4 h-4 group-hover:-translate-y-0.5 transition-transform" />
            <span>{t.downloadMac}</span>
          </a>

          <a
            href="/downloads/PopClick.zip"
            download
            className="w-full sm:w-auto flex items-center justify-center gap-2 px-6 py-3.5 rounded-xl font-medium text-neutral-300 bg-white/[0.05] hover:bg-white/[0.1] border border-white/[0.12] hover:text-white transition-all hover:scale-[1.02] active:scale-[0.98]"
          >
            <Terminal className="w-4 h-4 text-neutral-400" />
            <span>{t.downloadZip}</span>
          </a>

          <a
            href="https://github.com/bin158/popclick"
            target="_blank"
            rel="noopener noreferrer"
            className="w-full sm:w-auto flex items-center justify-center gap-2 px-5 py-3.5 rounded-xl font-medium text-neutral-400 hover:text-white transition-colors"
          >
            <span>{t.github}</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </a>
        </div>

        {/* System Requirements & Trust Badges */}
        <div className="flex flex-wrap items-center justify-center gap-y-2 gap-x-6 text-xs text-neutral-400">
          <div className="flex items-center gap-1.5">
            <Cpu className="w-3.5 h-3.5 text-blue-400" />
            <span>Apple Silicon & Intel Universal</span>
          </div>
          <div className="flex items-center gap-1.5">
            <ShieldCheck className="w-3.5 h-3.5 text-green-400" />
            <span>100% Offline Math • Zero Telemetry</span>
          </div>
          <div>
            <span>{t.requirements}</span>
          </div>
        </div>
      </div>
    </section>
  );
};
