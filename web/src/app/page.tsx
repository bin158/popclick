"use client";

import React, { useState } from "react";
import { Language } from "@/lib/translations";
import { Navbar } from "@/components/Navbar";
import { Hero } from "@/components/Hero";
import { InteractiveDemo } from "@/components/InteractiveDemo";
import { Features } from "@/components/Features";
import { Comparison } from "@/components/Comparison";
import { DownloadSection } from "@/components/DownloadSection";
import { FAQ } from "@/components/FAQ";
import { Footer } from "@/components/Footer";

export default function Home() {
  const [lang, setLang] = useState<Language>("zh");

  const toggleLanguage = () => {
    setLang((prev) => (prev === "en" ? "zh" : "en"));
  };

  return (
    <div className="flex flex-col min-h-screen">
      <Navbar lang={lang} onToggleLang={toggleLanguage} />
      <main className="flex-1">
        <Hero lang={lang} />
        <InteractiveDemo lang={lang} />
        <Features lang={lang} />
        <Comparison lang={lang} />
        <DownloadSection lang={lang} />
        <FAQ lang={lang} />
      </main>
      <Footer lang={lang} />
    </div>
  );
}
