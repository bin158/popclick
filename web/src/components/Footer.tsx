"use client";

import React from "react";
import { Github, Heart } from "lucide-react";
import { Language, translations } from "@/lib/translations";

interface FooterProps {
  lang: Language;
}

export const Footer: React.FC<FooterProps> = ({ lang }) => {
  const t = translations[lang].footer;

  return (
    <footer className="w-full border-t border-white/[0.08] bg-[#07080a] py-12 md:py-16">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        <div className="flex flex-col md:flex-row items-start justify-between gap-8 mb-12">
          {/* Brand info */}
          <div className="max-w-sm">
            <div className="flex items-center gap-2 mb-3">
              <div className="w-6 h-6 rounded-lg bg-blue-600 flex items-center justify-center">
                <span className="text-white font-bold text-xs">✦</span>
              </div>
              <span className="font-bold text-base tracking-tight text-white">
                PopClick
              </span>
              <span className="text-[10px] text-blue-400 font-semibold px-2 py-0.5 rounded-full bg-blue-500/10 border border-blue-500/20">
                v1.0.0
              </span>
            </div>
            <p className="text-xs text-neutral-400 leading-relaxed mb-4">
              {t.desc}
            </p>
            <div className="flex items-center gap-3">
              <a
                href="https://github.com/bin158/popclick"
                target="_blank"
                rel="noopener noreferrer"
                className="w-8 h-8 rounded-lg bg-white/[0.05] hover:bg-white/[0.1] border border-white/[0.08] flex items-center justify-center text-neutral-400 hover:text-white transition-colors"
              >
                <Github className="w-4 h-4" />
              </a>
            </div>
          </div>

          {/* Links columns */}
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-8 text-xs">
            <div>
              <div className="font-semibold text-white uppercase tracking-wider mb-3">
                {t.product}
              </div>
              <ul className="space-y-2 text-neutral-400">
                <li><a href="#features" className="hover:text-white transition-colors">Features</a></li>
                <li><a href="#demo" className="hover:text-white transition-colors">Simulator</a></li>
                <li><a href="#comparison" className="hover:text-white transition-colors">Comparison</a></li>
                <li><a href="/downloads/PopClick.dmg" download className="text-blue-400 hover:text-blue-300 transition-colors">Download DMG</a></li>
              </ul>
            </div>

            <div>
              <div className="font-semibold text-white uppercase tracking-wider mb-3">
                {t.resources}
              </div>
              <ul className="space-y-2 text-neutral-400">
                <li><a href="https://github.com/bin158/popclick/blob/main/README.md" target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors">Documentation</a></li>
                <li><a href="https://github.com/bin158/popclick/blob/main/LICENSE" target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors">MIT License</a></li>
                <li><a href="https://github.com/bin158/popclick/releases" target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors">Release Notes</a></li>
              </ul>
            </div>

            <div>
              <div className="font-semibold text-white uppercase tracking-wider mb-3">
                {t.community}
              </div>
              <ul className="space-y-2 text-neutral-400">
                <li><a href="https://github.com/bin158/popclick" target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors">GitHub Repository</a></li>
                <li><a href="https://github.com/bin158/popclick/issues" target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors">Issue Tracker</a></li>
              </ul>
            </div>
          </div>
        </div>

        {/* Bottom copyright */}
        <div className="pt-8 border-t border-white/[0.06] flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-neutral-500">
          <div className="flex items-center gap-1">
            <span>Crafted with</span>
            <Heart className="w-3.5 h-3.5 text-red-500 fill-red-500 inline" />
            <span>for macOS Power Users.</span>
          </div>
          <div>
            <span>© {new Date().getFullYear()} PopClick. {t.rights}</span>
          </div>
        </div>
      </div>
    </footer>
  );
};
