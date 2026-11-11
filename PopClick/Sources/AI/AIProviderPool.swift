import Foundation

/// Supported AI provider definition
struct AIProviderEntry: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var endpoint: String
    var apiKey: String
    var model: String
    var isEnabled: Bool
    var freeKeyURL: String
    var freeQuotaDescription: String

    var isReady: Bool {
        return isEnabled && (!apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || id == "ollama")
    }

    static let defaultPool: [AIProviderEntry] = [
        AIProviderEntry(
            id: "gemini",
            name: "Google Gemini (AI Studio)",
            endpoint: "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent",
            apiKey: "",
            model: "gemini-flash-lite-latest",
            isEnabled: true,
            freeKeyURL: "https://aistudio.google.com/app/apikey",
            freeQuotaDescription: "100% Free · 15 RPM · 1500 Req/Day (无需信用卡)"
        ),
        AIProviderEntry(
            id: "groq",
            name: "Groq Cloud (LPU)",
            endpoint: "https://api.groq.com/openai/v1/chat/completions",
            apiKey: "",
            model: "openai/gpt-oss-120b",
            isEnabled: true,
            freeKeyURL: "https://console.groq.com/keys",
            freeQuotaDescription: "100% Free · 30 RPM · 极速 500+ tok/s"
        ),
        AIProviderEntry(
            id: "openrouter",
            name: "OpenRouter Free Models",
            endpoint: "https://openrouter.ai/api/v1/chat/completions",
            apiKey: "",
            model: "openrouter/free",
            isEnabled: true,
            freeKeyURL: "https://openrouter.ai/keys",
            freeQuotaDescription: "100% Free · 包含 DeepSeek-R1, Gemini, Llama-3.3"
        ),
        AIProviderEntry(
            id: "ollama",
            name: "Ollama (Local Offline)",
            endpoint: "http://localhost:11434/v1/chat/completions",
            apiKey: "",
            model: "llama3.2",
            isEnabled: false,
            freeKeyURL: "https://ollama.com",
            freeQuotaDescription: "100% 本地运行 · 离线私密 · 零额度限制"
        )
    ]
}
