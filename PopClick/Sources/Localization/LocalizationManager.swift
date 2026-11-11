import Foundation

/// Lightweight native localization manager for English and Simplified Chinese
@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    enum Language: String, CaseIterable, Identifiable {
        case auto = "Auto (System)"
        case en = "English"
        case zhHans = "简体中文"

        var id: String { rawValue }
    }

    @Published var currentLanguage: Language = .auto {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = Language(rawValue: saved) {
            currentLanguage = lang
        }
    }

    var isChinese: Bool {
        switch currentLanguage {
        case .zhHans:
            return true
        case .en:
            return false
        case .auto:
            let preferred = Locale.preferredLanguages.first ?? "en"
            return preferred.hasPrefix("zh")
        }
    }

    func localized(_ en: String, _ zh: String) -> String {
        return isChinese ? zh : en
    }
}
