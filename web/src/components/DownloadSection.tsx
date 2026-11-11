"use client";

import React, { useState } from "react";
import { Download, Terminal, Check, Copy, Shield, Apple } from "lucide-react";
import { Language, translations } from "@/lib/translations";

interface DownloadSectionProps {
  lang: Language;
}

export const DownloadSection: React.FC<DownloadSectionProps> = ({ lang }) => {
  const t = translations[lang].download;
  const [copiedSha, setCopiedSha] = useState<boolean>(false);
  const [copiedCurl, setCopiedCurl] = useState<boolean>(false);

  const dmgSha = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
  const curlCmd = `curl -O https://github.com/bin158/popclick/releases/latest/download/PopClick.dmg`;

  const copyToClipboard = (text: string, type: "sha" | "curl") => {
    navigator.clipboard.writeText(text);
    if (type === "sha") {
      setCopiedSha(true);
      setTimeout(() => setCopiedSha(false), 2000);
    } else {
      setCopiedCurl(true);
      setTimeout(() => setCopiedCurl(false), 2000);
    }
  };

  return (
    <section id="download" className="py-20 md:py-28 relative">
      <div className="max-w-5xl mx-auto px-4 sm:px-6">
        <div className="glass-panel rounded-3xl p-8 sm:p-12 border border-white/[0.12] relative overflow-hidden">
          {/* Subtle Glow inside */}
          <div className="absolute top-0 right-0 w-96 h-96 bg-blue-500/10 blur-[100px] rounded-full pointer-events-none" />

          <div className="text-center max-w-2xl mx-auto mb-10">
            <div className="inline-block px-3 py-1 rounded-full text-xs font-bold text-blue-400 bg-blue-500/10 border border-blue-500/20 mb-3 tracking-wider">
              {t.tag}
            </div>
            <h2 className="text-3xl sm:text-4xl md:text-5xl font-extrabold tracking-tight text-white mb-4">
              {t.title}
            </h2>
            <p className="text-neutral-400 text-sm sm:text-base">
              {t.subtitle}
            </p>
          </div>

          {/* Download Buttons */}
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-12">
            <a
              href="/downloads/PopClick.dmg"
              download
              className="w-full sm:w-auto flex items-center justify-center gap-3 px-8 py-4 rounded-xl font-bold text-white bg-blue-600 hover:bg-blue-500 shadow-xl shadow-blue-600/35 transition-all hover:scale-[1.02] active:scale-[0.98]"
            >
              <Apple className="w-5 h-5 fill-current" />
              <div className="text-left">
                <div className="text-xs text-blue-200 uppercase font-semibold">macOS Disk Image</div>
                <div className="text-sm sm:text-base font-bold">PopClick.dmg (2.0 MB)</div>
              </div>
            </a>

            <a
              href="/downloads/PopClick.zip"
              download
              className="w-full sm:w-auto flex items-center justify-center gap-3 px-8 py-4 rounded-xl font-semibold text-neutral-200 bg-white/[0.06] hover:bg-white/[0.1] border border-white/[0.12] hover:text-white transition-all hover:scale-[1.02] active:scale-[0.98]"
            >
              <Download className="w-5 h-5 text-neutral-400" />
              <div className="text-left">
                <div className="text-xs text-neutral-400 uppercase font-semibold">ZIP Archive</div>
                <div className="text-sm sm:text-base font-bold">PopClick.zip (1.6 MB)</div>
              </div>
            </a>
          </div>

          {/* 3 Step Installation Flow */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-10">
            <div className="p-4 rounded-xl bg-white/[0.03] border border-white/[0.06]">
              <div className="text-blue-400 font-bold text-xs uppercase mb-1">Step 01</div>
              <p className="text-xs sm:text-sm text-neutral-300 font-medium">{t.step1}</p>
            </div>
            <div className="p-4 rounded-xl bg-white/[0.03] border border-white/[0.06]">
              <div className="text-blue-400 font-bold text-xs uppercase mb-1">Step 02</div>
              <p className="text-xs sm:text-sm text-neutral-300 font-medium">{t.step2}</p>
            </div>
            <div className="p-4 rounded-xl bg-white/[0.03] border border-white/[0.06]">
              <div className="text-blue-400 font-bold text-xs uppercase mb-1">Step 03</div>
              <p className="text-xs sm:text-sm text-neutral-300 font-medium">{t.step3}</p>
            </div>
          </div>

          {/* Terminal Command & SHA Verification */}
          <div className="border-t border-white/[0.08] pt-8 flex flex-col md:flex-row items-center justify-between gap-6 text-xs text-neutral-400 font-mono">
            {/* Terminal snippet */}
            <div className="w-full md:w-auto flex items-center justify-between gap-3 p-3 rounded-xl bg-black/50 border border-white/[0.08]">
              <div className="flex items-center gap-2 overflow-hidden text-neutral-300">
                <Terminal className="w-4 h-4 text-blue-400 flex-shrink-0" />
                <span className="truncate">{curlCmd}</span>
              </div>
              <button
                onClick={() => copyToClipboard(curlCmd, "curl")}
                className="p-1.5 rounded-lg hover:bg-white/10 text-neutral-400 hover:text-white transition-colors"
                title="Copy Terminal Command"
              >
                {copiedCurl ? <Check className="w-3.5 h-3.5 text-green-400" /> : <Copy className="w-3.5 h-3.5" />}
              </button>
            </div>

            {/* SHA Hash snippet */}
            <div className="w-full md:w-auto flex items-center justify-between gap-3 p-3 rounded-xl bg-black/50 border border-white/[0.08]">
              <div className="flex items-center gap-2 overflow-hidden text-neutral-300">
                <Shield className="w-4 h-4 text-green-400 flex-shrink-0" />
                <span className="truncate max-w-[200px]">SHA256: {dmgSha}</span>
              </div>
              <button
                onClick={() => copyToClipboard(dmgSha, "sha")}
                className="p-1.5 rounded-lg hover:bg-white/10 text-neutral-400 hover:text-white transition-colors"
                title="Copy SHA-256 Checksum"
              >
                {copiedSha ? <Check className="w-3.5 h-3.5 text-green-400" /> : <Copy className="w-3.5 h-3.5" />}
              </button>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
