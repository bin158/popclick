"use client";

import React from "react";
import { Cpu, Zap, HardDrive, MemoryStick, Sigma, ShieldCheck } from "lucide-react";
import { Language, translations } from "@/lib/translations";

interface PerformanceProps {
  lang: Language;
}

export const Performance: React.FC<PerformanceProps> = ({ lang }) => {
  const t = translations[lang].specs;

  const metrics = [
    {
      val: t.m1Val,
      label: t.m1Label,
      desc: t.m1Desc,
      icon: <Cpu className="w-5 h-5 text-blue-400" />,
      color: "from-blue-500/20 to-blue-600/5",
    },
    {
      val: t.m2Val,
      label: t.m2Label,
      desc: t.m2Desc,
      icon: <Zap className="w-5 h-5 text-amber-400" />,
      color: "from-amber-500/20 to-amber-600/5",
    },
    {
      val: t.m3Val,
      label: t.m3Label,
      desc: t.m3Desc,
      icon: <HardDrive className="w-5 h-5 text-emerald-400" />,
      color: "from-emerald-500/20 to-emerald-600/5",
    },
    {
      val: t.m4Val,
      label: t.m4Label,
      desc: t.m4Desc,
      icon: <MemoryStick className="w-5 h-5 text-purple-400" />,
      color: "from-purple-500/20 to-purple-600/5",
    },
    {
      val: t.m5Val,
      label: t.m5Label,
      desc: t.m5Desc,
      icon: <Sigma className="w-5 h-5 text-cyan-400" />,
      color: "from-cyan-500/20 to-cyan-600/5",
    },
    {
      val: t.m6Val,
      label: t.m6Label,
      desc: t.m6Desc,
      icon: <ShieldCheck className="w-5 h-5 text-green-400" />,
      color: "from-green-500/20 to-green-600/5",
    },
  ];

  return (
    <section id="specs" className="py-20 md:py-28 relative">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        {/* Header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-block px-3 py-1 rounded-full text-xs font-bold text-blue-400 bg-blue-500/10 border border-blue-500/20 mb-3 tracking-wider">
            {t.tag}
          </div>
          <h2 className="text-3xl sm:text-4xl md:text-5xl font-extrabold tracking-tight text-white mb-4">
            {t.title}
          </h2>
          <p className="text-neutral-400 text-sm sm:text-base md:text-lg">
            {t.subtitle}
          </p>
        </div>

        {/* Specs Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {metrics.map((item, idx) => (
            <div
              key={idx}
              className="glass-panel rounded-2xl p-6 sm:p-8 flex flex-col justify-between border border-white/[0.08] hover:border-white/20 transition-all duration-300 hover:-translate-y-1 group relative overflow-hidden"
            >
              {/* Corner soft glow */}
              <div
                className={`absolute top-0 right-0 w-32 h-32 bg-gradient-to-br ${item.color} blur-2xl rounded-full pointer-events-none group-hover:scale-125 transition-transform duration-500`}
              />

              <div>
                <div className="flex items-center justify-between mb-4">
                  <div className="w-10 h-10 rounded-xl bg-white/[0.05] border border-white/[0.08] flex items-center justify-center">
                    {item.icon}
                  </div>
                </div>

                <div className="text-3xl sm:text-4xl font-extrabold tracking-tight text-white mb-1.5 font-mono">
                  {item.val}
                </div>

                <h3 className="text-sm sm:text-base font-bold text-neutral-200 mb-2">
                  {item.label}
                </h3>

                <p className="text-xs sm:text-sm text-neutral-400 leading-relaxed">
                  {item.desc}
                </p>
              </div>

              <div className="mt-6 pt-4 border-t border-white/[0.06] flex items-center justify-between text-[11px] text-neutral-500 font-mono">
                <span>NATIVE ARCHITECTURE</span>
                <span className="text-green-400">OPTIMIZED</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
