import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        accent: {
          DEFAULT: "#007AFF",
          hover: "#0062cc",
          glow: "rgba(0, 122, 255, 0.35)",
        },
        surface: {
          dark: "#0b0c10",
          card: "#12131a",
          border: "rgba(255, 255, 255, 0.08)",
          hover: "rgba(255, 255, 255, 0.04)",
        }
      },
      fontFamily: {
        sans: ["-apple-system", "BlinkMacSystemFont", "SF Pro Display", "SF Pro Text", "Helvetica Neue", "sans-serif"],
        mono: ["SF Mono", "ui-monospace", "Menlo", "Consolas", "monospace"],
      },
      animation: {
        "float": "float 4s ease-in-out infinite",
        "pulse-subtle": "pulseSubtle 3s ease-in-out infinite",
      },
      keyframes: {
        float: {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-6px)" },
        },
        pulseSubtle: {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0.8" },
        }
      }
    },
  },
  plugins: [],
};
export default config;
