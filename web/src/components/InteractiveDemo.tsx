"use client";

import React, { useState } from "react";
import { 
  Code2, 
  Sigma, 
  FileText, 
  Braces, 
  Sparkles, 
  Copy, 
  Check, 
  Wrench, 
  ArrowRight,
  GitBranch,
  Search,
  Languages,
  MoreHorizontal
} from "lucide-react";
import { Language, translations } from "@/lib/translations";

interface DemoProps {
  lang: Language;
}

type TabType = "code" | "math" | "text" | "json";

export const InteractiveDemo: React.FC<DemoProps> = ({ lang }) => {
  const t = translations[lang].demo;
  const [activeTab, setActiveTab] = useState<TabType>("code");
  const [activeAction, setActiveAction] = useState<string>("fix");
  const [copied, setCopied] = useState<boolean>(false);
  const [isWordWrap, setIsWordWrap] = useState<boolean>(false);

  const handleCopy = () => {
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <section id="demo" className="py-12 md:py-20 relative">
      <div className="max-w-5xl mx-auto px-4 sm:px-6">
        <div className="text-center mb-10">
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight text-white mb-3">
            {t.title}
          </h2>
          <p className="text-neutral-400 text-sm sm:text-base max-w-2xl mx-auto">
            {t.subtitle}
          </p>
        </div>

        {/* Tab Switcher */}
        <div className="flex items-center justify-center gap-2 mb-8 overflow-x-auto pb-2">
          <button
            onClick={() => { setActiveTab("code"); setActiveAction("fix"); }}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs sm:text-sm font-medium transition-all ${
              activeTab === "code"
                ? "bg-blue-600 text-white shadow-lg shadow-blue-600/25"
                : "bg-white/[0.04] text-neutral-400 hover:text-white hover:bg-white/[0.08]"
            }`}
          >
            <Code2 className="w-4 h-4" />
            <span>{t.tabCode} (Swift/Python)</span>
          </button>

          <button
            onClick={() => { setActiveTab("math"); setActiveAction("katex"); }}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs sm:text-sm font-medium transition-all ${
              activeTab === "math"
                ? "bg-blue-600 text-white shadow-lg shadow-blue-600/25"
                : "bg-white/[0.04] text-neutral-400 hover:text-white hover:bg-white/[0.08]"
            }`}
          >
            <Sigma className="w-4 h-4" />
            <span>{t.tabMath} (KaTeX)</span>
          </button>

          <button
            onClick={() => { setActiveTab("text"); setActiveAction("translate"); }}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs sm:text-sm font-medium transition-all ${
              activeTab === "text"
                ? "bg-blue-600 text-white shadow-lg shadow-blue-600/25"
                : "bg-white/[0.04] text-neutral-400 hover:text-white hover:bg-white/[0.08]"
            }`}
          >
            <FileText className="w-4 h-4" />
            <span>{t.tabText}</span>
          </button>

          <button
            onClick={() => { setActiveTab("json"); setActiveAction("format"); }}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs sm:text-sm font-medium transition-all ${
              activeTab === "json"
                ? "bg-blue-600 text-white shadow-lg shadow-blue-600/25"
                : "bg-white/[0.04] text-neutral-400 hover:text-white hover:bg-white/[0.08]"
            }`}
          >
            <Braces className="w-4 h-4" />
            <span>{t.tabJson}</span>
          </button>
        </div>

        {/* Mac Window Simulation Frame */}
        <div className="rounded-2xl border border-white/[0.12] bg-[#0d0e14] shadow-2xl overflow-hidden relative">
          {/* macOS Title Bar */}
          <div className="h-10 px-4 bg-[#14161f] border-b border-white/[0.08] flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-[#ff5f56]" />
              <div className="w-3 h-3 rounded-full bg-[#ffbd2e]" />
              <div className="w-3 h-3 rounded-full bg-[#27c93f]" />
            </div>
            <div className="text-xs text-neutral-400 font-mono flex items-center gap-1.5">
              <span>Xcode / Editor Simulation</span>
              <span className="text-neutral-600">•</span>
              <span className="text-blue-400 font-medium">PopClick HUD Active</span>
            </div>
            <div className="w-12" />
          </div>

          {/* Simulator Content Workspace */}
          <div className="p-6 sm:p-8 relative min-h-[460px] flex flex-col justify-between">
            {/* The Floating PopClick Glass Capsule */}
            <div className="flex justify-center mb-6">
              <div className="glass-capsule rounded-full px-3 py-1.5 flex items-center gap-1 shadow-2xl animate-float">
                {activeTab === "code" && (
                  <>
                    <button onClick={handleCopy} className="flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium text-neutral-300 hover:bg-white/10 hover:text-white transition-all">
                      {copied ? <Check className="w-3.5 h-3.5 text-green-400" /> : <Copy className="w-3.5 h-3.5" />}
                      <span>Copy</span>
                    </button>
                    <button onClick={() => setActiveAction("explain")} className={`px-2.5 py-1 rounded-full text-xs font-medium transition-all ${activeAction === "explain" ? "bg-blue-600 text-white" : "text-neutral-300 hover:bg-white/10"}`}>
                      Explain
                    </button>
                    <button onClick={() => setActiveAction("comment")} className={`px-2.5 py-1 rounded-full text-xs font-medium transition-all ${activeAction === "comment" ? "bg-blue-600 text-white" : "text-neutral-300 hover:bg-white/10"}`}>
                      Comment
                    </button>
                    <button onClick={() => setActiveAction("fix")} className={`flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold transition-all ${activeAction === "fix" ? "bg-blue-600 text-white shadow-sm shadow-blue-500/50" : "text-blue-400 hover:bg-white/10"}`}>
                      <Wrench className="w-3 h-3" />
                      <span>Fix</span>
                    </button>
                    <button onClick={() => setActiveAction("refactor")} className={`px-2.5 py-1 rounded-full text-xs font-medium transition-all ${activeAction === "refactor" ? "bg-blue-600 text-white" : "text-neutral-300 hover:bg-white/10"}`}>
                      Refactor
                    </button>
                    <button onClick={() => setActiveAction("ai")} className="flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold text-blue-400 hover:bg-white/10">
                      <Sparkles className="w-3 h-3" />
                      <span>AI</span>
                    </button>
                  </>
                )}

                {activeTab === "math" && (
                  <>
                    <button onClick={handleCopy} className="flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium text-neutral-300 hover:bg-white/10">
                      <Copy className="w-3.5 h-3.5" />
                      <span>Copy</span>
                    </button>
                    <button onClick={() => setActiveAction("katex")} className="px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-600 text-white">
                      ∑ Render KaTeX
                    </button>
                    <button onClick={() => setActiveAction("explain")} className="px-2.5 py-1 rounded-full text-xs font-medium text-neutral-300 hover:bg-white/10">
                      Explain Math
                    </button>
                    <button className="flex items-center gap-1 px-2 py-1 rounded-full text-xs text-neutral-400 hover:bg-white/10">
                      <MoreHorizontal className="w-3.5 h-3.5" />
                    </button>
                  </>
                )}

                {activeTab === "text" && (
                  <>
                    <button onClick={handleCopy} className="flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium text-neutral-300 hover:bg-white/10">
                      <Copy className="w-3.5 h-3.5" />
                      <span>Copy</span>
                    </button>
                    <button onClick={() => setActiveAction("search")} className="flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium text-neutral-300 hover:bg-white/10">
                      <Search className="w-3 h-3" />
                      <span>Search</span>
                    </button>
                    <button onClick={() => setActiveAction("translate")} className={`flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium transition-all ${activeAction === "translate" ? "bg-blue-600 text-white" : "text-neutral-300 hover:bg-white/10"}`}>
                      <Languages className="w-3 h-3" />
                      <span>Translate</span>
                    </button>
                    <button onClick={() => setActiveAction("ai")} className="flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold text-blue-400 hover:bg-white/10">
                      <Sparkles className="w-3 h-3" />
                      <span>AI</span>
                    </button>
                    <button className="flex items-center gap-1 px-2 py-1 rounded-full text-xs text-neutral-400 hover:bg-white/10">
                      <MoreHorizontal className="w-3.5 h-3.5" />
                    </button>
                  </>
                )}

                {activeTab === "json" && (
                  <>
                    <button onClick={handleCopy} className="flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium text-neutral-300 hover:bg-white/10">
                      <Copy className="w-3.5 h-3.5" />
                      <span>Copy</span>
                    </button>
                    <button onClick={() => setActiveAction("format")} className="px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-600 text-white">
                      Format JSON
                    </button>
                    <button onClick={() => setActiveAction("validate")} className="px-2.5 py-1 rounded-full text-xs font-medium text-neutral-300 hover:bg-white/10">
                      Validate
                    </button>
                    <button onClick={() => setActiveAction("explain")} className="px-2.5 py-1 rounded-full text-xs font-medium text-neutral-300 hover:bg-white/10">
                      Explain
                    </button>
                  </>
                )}
              </div>
            </div>

            {/* Simulated Selection & AI Agent Diff Output View */}
            <div className="flex-1 rounded-xl bg-black/40 border border-white/[0.08] p-4 sm:p-5 font-mono text-xs sm:text-sm">
              {activeTab === "code" && (
                <div>
                  {activeAction === "fix" || activeAction === "refactor" ? (
                    <div>
                      {/* Diff Header */}
                      <div className="flex items-center justify-between pb-3 mb-3 border-b border-white/[0.08] text-xs">
                        <div className="flex items-center gap-2">
                          <GitBranch className="w-3.5 h-3.5 text-blue-400" />
                          <span className="font-semibold text-neutral-300">{t.diffTitle}</span>
                          <span className="px-1.5 py-0.5 rounded bg-blue-500/10 text-blue-400 text-[10px] font-bold">SWIFT</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="px-1.5 py-0.5 rounded bg-green-500/10 text-green-400 text-[10px] font-bold">+2</span>
                          <span className="px-1.5 py-0.5 rounded bg-red-500/10 text-red-400 text-[10px] font-bold">-1</span>
                          <button onClick={() => setIsWordWrap(!isWordWrap)} className="text-[10px] text-neutral-400 hover:text-white px-2 py-0.5 rounded bg-white/5">
                            {isWordWrap ? "Unwrap" : "Wrap"}
                          </button>
                        </div>
                      </div>

                      {/* Diff Line-by-Line Presentation */}
                      <div className={`space-y-1 font-mono text-xs leading-relaxed ${isWordWrap ? "whitespace-pre-wrap" : "overflow-x-auto"}`}>
                        <div className="text-neutral-500 pl-4">1  func calculateTotal(items: [Item]?) -&gt; Double &#123;</div>
                        <div className="bg-red-500/15 text-red-300 px-2 py-0.5 rounded flex items-center">
                          <span className="w-6 text-red-400/60 font-semibold">- 2</span>
                          <span>&nbsp;&nbsp;&nbsp;&nbsp;return items.reduce(0) &#123; $0 + $1.price &#125; // Crash if nil!</span>
                        </div>
                        <div className="bg-green-500/15 text-green-300 px-2 py-0.5 rounded flex items-center">
                          <span className="w-6 text-green-400/60 font-semibold">+ 2</span>
                          <span>&nbsp;&nbsp;&nbsp;&nbsp;guard let validItems = items else &#123; return 0.0 &#125;</span>
                        </div>
                        <div className="bg-green-500/15 text-green-300 px-2 py-0.5 rounded flex items-center">
                          <span className="w-6 text-green-400/60 font-semibold">+ 3</span>
                          <span>&nbsp;&nbsp;&nbsp;&nbsp;return validItems.reduce(0) &#123; $0 + $1.price &#125;</span>
                        </div>
                        <div className="text-neutral-500 pl-4">4  &#125;</div>
                      </div>

                      {/* Action Bar */}
                      <div className="mt-4 pt-3 border-t border-white/[0.08] flex items-center justify-between">
                        <span className="text-neutral-400 text-xs">
                          {lang === "en" ? "✓ Replaces ONLY your selected lines" : "✓ 严格仅替换您当前鼠标选中的代码行"}
                        </span>
                        <button 
                          onClick={handleCopy}
                          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold text-white bg-blue-600 hover:bg-blue-500 transition-colors shadow-sm"
                        >
                          {copied ? <Check className="w-3.5 h-3.5" /> : <ArrowRight className="w-3.5 h-3.5" />}
                          <span>{t.replaceBtn}</span>
                        </button>
                      </div>
                    </div>
                  ) : (
                    <div className="text-neutral-300 space-y-2 text-xs leading-relaxed">
                      <p className="text-blue-400 font-semibold">✦ PopClick AI Agent Analysis (Swift):</p>
                      <p>The function safely handles optional item arrays and computes the total sum using functional reduce.</p>
                      <div className="p-3 bg-neutral-900 rounded-lg text-neutral-400 mt-2">
                        Time Complexity: <span className="text-green-400 font-bold">O(N)</span> • Memory: <span className="text-green-400 font-bold">O(1)</span>
                      </div>
                    </div>
                  )}
                </div>
              )}

              {activeTab === "math" && (
                <div className="space-y-4">
                  <div className="text-xs text-neutral-400 border-b border-white/[0.08] pb-2 flex items-center justify-between">
                    <span>100% OFFLINE KaTeX LATEX RENDERING</span>
                    <span className="text-green-400 font-bold text-[10px]">NO INTERNET NEEDED</span>
                  </div>
                  <div className="py-6 flex flex-col items-center justify-center gap-4 text-center">
                    <div className="text-2xl font-serif text-white tracking-wider">
                      {"$$\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}$$"}
                    </div>
                    <div className="text-lg font-serif text-neutral-300">
                      {"$$[a]_R = \\{ s \\in S \\mid (a, s) \\in R \\}$$"}
                    </div>
                  </div>
                  <div className="text-[11px] text-neutral-500 text-center">
                    {lang === "en" ? "Rendered natively with local bundled WOFF2 fonts and marked.js" : "由本地内嵌的 WOFF2 字体与 KaTeX 脚本瞬时离线解析"}
                  </div>
                </div>
              )}

              {activeTab === "text" && (
                <div className="space-y-4">
                  <div className="p-3 bg-white/[0.03] rounded-lg border border-white/[0.06]">
                    <span className="text-xs text-neutral-400 block mb-1">ORIGINAL SELECTION:</span>
                    <p className="text-neutral-200 text-sm">
                      &quot;PopClick is designed with an uncompromising standard for micro-interactions and visual aesthetics.&quot;
                    </p>
                  </div>
                  <div className="p-3 bg-blue-500/10 rounded-lg border border-blue-500/20">
                    <span className="text-xs text-blue-400 font-semibold block mb-1">TRANSLATED (CHINESE):</span>
                    <p className="text-white text-sm">
                      &quot;PopClick 遵循对微交互和视觉美学毫不妥协的严苛标准而精雕细琢。&quot;
                    </p>
                  </div>
                </div>
              )}

              {activeTab === "json" && (
                <div>
                  <div className="text-xs text-neutral-400 border-b border-white/[0.08] pb-2 flex items-center justify-between mb-3">
                    <span>FAULT-TOLERANT JSON FORMATTER</span>
                    <span className="text-green-400 font-bold text-[10px]">FIXED &amp; VALIDATED</span>
                  </div>
                  <pre className="text-green-300 text-xs leading-relaxed overflow-x-auto">
{`{
  "name": "PopClick",
  "version": "1.0.0",
  "aiAgent": "PopClick AI Agent",
  "offlineMath": true,
  "idleCpu": 0.0,
  "platforms": ["Apple Silicon", "Intel"]
}`}
                  </pre>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
