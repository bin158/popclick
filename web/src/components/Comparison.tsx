"use client";

import React from "react";
import { Check, X } from "lucide-react";
import { Language, translations } from "@/lib/translations";

interface ComparisonProps {
  lang: Language;
}

export const Comparison: React.FC<ComparisonProps> = ({ lang }) => {
  const t = translations[lang].compare;

  const rows = [
    {
      feature: t.f1,
      popclick: t.f1V1,
      popclip: t.f1V2,
      electron: t.f1V3,
      isHighlight: true,
    },
    {
      feature: t.f2,
      popclick: t.f2V1,
      popclip: t.f2V2,
      electron: t.f2V3,
      isHighlight: true,
    },
    {
      feature: t.f3,
      popclick: t.f3V1,
      popclip: t.f3V2,
      electron: t.f3V3,
      isHighlight: false,
    },
    {
      feature: t.f4,
      popclick: t.f4V1,
      popclip: t.f4V2,
      electron: t.f4V3,
      isHighlight: true,
    },
    {
      feature: t.f5,
      popclick: t.f5V1,
      popclip: t.f5V2,
      electron: t.f5V3,
      isHighlight: false,
    },
    {
      feature: t.f6,
      popclick: t.f6V1,
      popclip: t.f6V2,
      electron: t.f6V3,
      isHighlight: true,
    },
  ];

  return (
    <section id="comparison" className="py-20 md:py-28 relative">
      <div className="max-w-5xl mx-auto px-4 sm:px-6">
        <div className="text-center max-w-2xl mx-auto mb-16">
          <div className="inline-block px-3 py-1 rounded-full text-xs font-bold text-blue-400 bg-blue-500/10 border border-blue-500/20 mb-3 tracking-wider">
            {t.tag}
          </div>
          <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-white mb-4">
            {t.title}
          </h2>
          <p className="text-neutral-400 text-sm sm:text-base">
            {t.subtitle}
          </p>
        </div>

        {/* Comparison Table */}
        <div className="glass-panel rounded-2xl overflow-hidden border border-white/[0.1]">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-white/[0.08] bg-white/[0.02]">
                  <th className="py-4 px-6 font-semibold text-neutral-400 text-xs tracking-wider uppercase">
                    {t.colFeature}
                  </th>
                  <th className="py-4 px-6 font-bold text-blue-400 text-sm bg-blue-500/[0.06] border-x border-blue-500/20">
                    ✦ {t.colPopClick}
                  </th>
                  <th className="py-4 px-6 font-semibold text-neutral-400 text-xs tracking-wider uppercase">
                    {t.colPopClip}
                  </th>
                  <th className="py-4 px-6 font-semibold text-neutral-400 text-xs tracking-wider uppercase">
                    {t.colElectron}
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/[0.06]">
                {rows.map((row, idx) => (
                  <tr key={idx} className="hover:bg-white/[0.02] transition-colors">
                    <td className="py-4 px-6 font-medium text-white text-xs sm:text-sm">
                      {row.feature}
                    </td>
                    <td className="py-4 px-6 font-semibold text-white bg-blue-500/[0.04] border-x border-blue-500/20 text-xs sm:text-sm">
                      <div className="flex items-center gap-2">
                        <Check className="w-4 h-4 text-blue-400 flex-shrink-0" />
                        <span>{row.popclick}</span>
                      </div>
                    </td>
                    <td className="py-4 px-6 text-neutral-400 text-xs sm:text-sm">
                      {row.popclip}
                    </td>
                    <td className="py-4 px-6 text-neutral-400 text-xs sm:text-sm">
                      <div className="flex items-center gap-1.5">
                        <X className="w-3.5 h-3.5 text-neutral-600 flex-shrink-0" />
                        <span>{row.electron}</span>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </section>
  );
};
