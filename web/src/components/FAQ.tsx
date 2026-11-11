"use client";

import React, { useState } from "react";
import { ChevronDown } from "lucide-react";
import { Language, translations } from "@/lib/translations";

interface FAQProps {
  lang: Language;
}

export const FAQ: React.FC<FAQProps> = ({ lang }) => {
  const t = translations[lang].faq;
  const [openIdx, setOpenIdx] = useState<number | null>(0);

  const faqs = [
    { q: t.q1, a: t.a1 },
    { q: t.q2, a: t.a2 },
    { q: t.q3, a: t.a3 },
    { q: t.q4, a: t.a4 },
  ];

  return (
    <section id="faq" className="py-20 md:py-28 relative">
      <div className="max-w-4xl mx-auto px-4 sm:px-6">
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-white mb-3">
            {t.title}
          </h2>
          <p className="text-neutral-400 text-sm sm:text-base">
            {lang === "en" ? "Everything you need to know about PopClick on macOS." : "关于 PopClick 在 Mac 上运行与安全性的详尽解答。"}
          </p>
        </div>

        <div className="space-y-3">
          {faqs.map((item, idx) => {
            const isOpen = openIdx === idx;
            return (
              <div
                key={idx}
                className="glass-panel rounded-2xl overflow-hidden border border-white/[0.08] transition-colors"
              >
                <button
                  onClick={() => setOpenIdx(isOpen ? null : idx)}
                  className="w-full py-4 px-6 flex items-center justify-between text-left transition-colors hover:bg-white/[0.02]"
                >
                  <span className="font-semibold text-white text-sm sm:text-base">
                    {item.q}
                  </span>
                  <ChevronDown
                    className={`w-4 h-4 text-neutral-400 transition-transform duration-200 ${
                      isOpen ? "rotate-180 text-blue-400" : ""
                    }`}
                  />
                </button>
                {isOpen && (
                  <div className="px-6 pb-5 pt-1 text-xs sm:text-sm text-neutral-400 leading-relaxed border-t border-white/[0.04]">
                    {item.a}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
};
