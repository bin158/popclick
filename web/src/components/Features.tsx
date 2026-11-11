"use client";

import React from "react";
import { 
  Zap, 
  Sparkles, 
  Code2, 
  Sigma, 
  GitCompare, 
  Braces 
} from "lucide-react";
import { Language, translations } from "@/lib/translations";

interface FeaturesProps {
  lang: Language;
}

export const Features: React.FC<FeaturesProps> = ({ lang }) => {
  const t = translations[lang].features;

  const featureCards = [
    {
      icon: <Zap className="w-5 h-5 text-blue-400" />,
      title: t.f1Title,
      desc: t.f1Desc,
      tag: "0% IDLE CPU",
    },
    {
      icon: <Sparkles className="w-5 h-5 text-purple-400" />,
      title: t.f2Title,
      desc: t.f2Desc,
      tag: "AI AGENT",
    },
    {
      icon: <Code2 className="w-5 h-5 text-emerald-400" />,
      title: t.f3Title,
      desc: t.f3Desc,
      tag: "18+ LANGUAGES",
    },
    {
      icon: <Sigma className="w-5 h-5 text-amber-400" />,
      title: t.f4Title,
      desc: t.f4Desc,
      tag: "OFFLINE LATEX",
    },
    {
      icon: <GitCompare className="w-5 h-5 text-cyan-400" />,
      title: t.f5Title,
      desc: t.f5Desc,
      tag: "LCS DIFF ENGINE",
    },
    {
      icon: <Braces className="w-5 h-5 text-pink-400" />,
      title: t.f6Title,
      desc: t.f6Desc,
      tag: "TOLERANT PARSER",
    },
  ];

  return (
    <section id="features" className="py-20 md:py-28 relative">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-block px-3 py-1 rounded-full text-xs font-bold text-blue-400 bg-blue-500/10 border border-blue-500/20 mb-3 tracking-wider">
            {t.tag}
          </div>
          <h2 className="text-3xl sm:text-4xl md:text-5xl font-extrabold tracking-tight text-white mb-4">
            {t.title}
          </h2>
          <p className="text-neutral-400 text-base sm:text-lg">
            {t.subtitle}
          </p>
        </div>

        {/* Bento Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {featureCards.map((card, idx) => (
            <div
              key={idx}
              className="glass-panel rounded-2xl p-6 sm:p-7 flex flex-col justify-between hover:border-white/20 transition-all duration-300 hover:-translate-y-1 group"
            >
              <div>
                <div className="flex items-center justify-between mb-5">
                  <div className="w-10 h-10 rounded-xl bg-white/[0.06] border border-white/[0.08] flex items-center justify-center group-hover:scale-110 transition-transform">
                    {card.icon}
                  </div>
                  <span className="text-[10px] font-bold text-neutral-400 tracking-wider bg-white/[0.04] px-2.5 py-1 rounded-full border border-white/[0.06]">
                    {card.tag}
                  </span>
                </div>
                <h3 className="text-lg font-bold text-white mb-2.5 group-hover:text-blue-400 transition-colors">
                  {card.title}
                </h3>
                <p className="text-neutral-400 text-xs sm:text-sm leading-relaxed">
                  {card.desc}
                </p>
              </div>

              <div className="mt-6 pt-4 border-t border-white/[0.06] flex items-center gap-1.5 text-xs text-blue-400/80 font-medium group-hover:text-blue-400 transition-colors">
                <span>Learn more</span>
                <span className="group-hover:translate-x-1 transition-transform">→</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
