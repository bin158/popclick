import Foundation

/// Defines a supported translation language with code, localized display name, and country flag
struct TranslateLanguage: Identifiable, Hashable, Equatable {
    let code: String
    let name: String
    let flag: String

    var id: String { code }

    static let all: [TranslateLanguage] = [
        TranslateLanguage(code: "zh-CN", name: "简体中文", flag: "🇨🇳"),
        TranslateLanguage(code: "en", name: "English", flag: "🇺🇸"),
        TranslateLanguage(code: "ja", name: "日本語", flag: "🇯🇵"),
        TranslateLanguage(code: "ko", name: "한국어", flag: "🇰🇷"),
        TranslateLanguage(code: "fr", name: "Français", flag: "🇫🇷"),
        TranslateLanguage(code: "de", name: "Deutsch", flag: "🇩🇪"),
        TranslateLanguage(code: "es", name: "Español", flag: "🇪🇸"),
        TranslateLanguage(code: "ru", name: "Русский", flag: "🇷🇺"),
        TranslateLanguage(code: "it", name: "Italiano", flag: "🇮🇹"),
        TranslateLanguage(code: "pt", name: "Português", flag: "🇵🇹"),
        TranslateLanguage(code: "zh-TW", name: "繁體中文", flag: "🇹🇼"),
        TranslateLanguage(code: "ar", name: "العربية", flag: "🇸🇦"),
    ]

    static func from(code: String) -> TranslateLanguage {
        return all.first(where: { $0.code == code })
            ?? all.first(where: { code.hasPrefix($0.code) || $0.code.hasPrefix(code) })
            ?? TranslateLanguage(code: code, name: code, flag: "🌐")
    }
}

/// Fast, multi-tier translation service with Google Translate & neural fallback
@MainActor
final class TranslationService: ObservableObject {
    static let shared = TranslationService()

    struct TranslationResult {
        let originalText: String
        let translatedText: String
        let sourceLanguage: TranslateLanguage
        let targetLanguage: TranslateLanguage
    }

    private init() {}

    /// Detects whether text is primarily Chinese
    func isChineseText(_ text: String) -> Bool {
        return text.range(of: "\\p{Han}", options: .regularExpression) != nil
    }

    /// Performs translation with multi-tier fallback
    func translate(text: String, fromSourceLanguage: String = "auto", toTargetLanguage: String? = nil) async -> TranslationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isChinese = isChineseText(trimmed)

        let targetCode = toTargetLanguage ?? (isChinese ? "en" : "zh-CN")
        let sourceCode = fromSourceLanguage == "auto" ? (isChinese ? "zh-CN" : "en") : fromSourceLanguage

        let targetLang = TranslateLanguage.from(code: targetCode)
        let sourceLang = TranslateLanguage.from(code: sourceCode)

        guard !trimmed.isEmpty else {
            return TranslationResult(originalText: text, translatedText: "", sourceLanguage: sourceLang, targetLanguage: targetLang)
        }

        // 1. Try Google Translate API first (supports any language code)
        if let googleResult = await fetchGoogleTranslate(text: trimmed, source: fromSourceLanguage, target: targetCode) {
            return TranslationResult(
                originalText: text,
                translatedText: googleResult,
                sourceLanguage: sourceLang,
                targetLanguage: targetLang
            )
        }

        // 2. Fallback to MyMemory Neural API
        if let memoryResult = await fetchMyMemoryTranslate(text: trimmed, source: sourceCode, target: targetCode) {
            return TranslationResult(
                originalText: text,
                translatedText: memoryResult,
                sourceLanguage: sourceLang,
                targetLanguage: targetLang
            )
        }

        // 3. Fallback to AI Engine / Local Smart Translation
        let aiResult = await AIService.shared.process(action: .translate, text: trimmed)
        return TranslationResult(
            originalText: text,
            translatedText: aiResult,
            sourceLanguage: sourceLang,
            targetLanguage: targetLang
        )
    }

    // MARK: - Providers

    private func fetchGoogleTranslate(text: String, source: String, target: String) async -> String? {
        var components = URLComponents(string: "https://translate.googleapis.com/translate_a/single")
        components?.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: source),
            URLQueryItem(name: "tl", value: target),
            URLQueryItem(name: "dt", value: "t"),
            URLQueryItem(name: "q", value: text)
        ]

        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 4.0
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
               let sentences = json.first as? [[Any]] {
                let translated = sentences.compactMap { $0.first as? String }.joined()
                if !translated.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return translated
                }
            }
        } catch {
            // Silently fall through
        }

        return nil
    }

    private func fetchMyMemoryTranslate(text: String, source: String, target: String) async -> String? {
        var components = URLComponents(string: "https://api.mymemory.translated.net/get")
        components?.queryItems = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "langpair", value: "\(source)|\(target)")
        ]

        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let responseData = json["responseData"] as? [String: Any],
               let translated = responseData["translatedText"] as? String {
                let cleaned = translated.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty {
                    return cleaned
                }
            }
        } catch {
            // Silently fall through
        }

        return nil
    }
}
