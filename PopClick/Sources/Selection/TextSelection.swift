import Foundation

/// Represents a detected text selection with its content, geometry, and contextual semantics
struct TextSelection {
    let text: String
    let bounds: CGRect         // Screen coordinates of the selection (Cocoa bottom-left origin)
    let mouseLocation: CGPoint   // Mouse position at time of selection
    let contentType: ContentType

    /// Detected type of selected content
    enum ContentType {
        case plainText
        case url
        case email
        case code
        case number

        var suggestedActions: [ActionType] {
            switch self {
            case .plainText:
                return [.copy, .search, .translate, .ai, .more]
            case .url:
                return [.openURL, .copy, .share, .ai, .more]
            case .email:
                return [.email, .copy, .ai, .more]
            case .code:
                return [.copy, .formatJSON, .ai, .more]
            case .number:
                return [.copy, .search, .ai, .more]
            }
        }
    }

    /// Detect content type from text
    static func detectContentType(_ text: String) -> ContentType {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // URL detection
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
           let match = detector.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           match.range.length == trimmed.count {
            return .url
        }

        // Email detection
        let emailPattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        if trimmed.range(of: emailPattern, options: .regularExpression) != nil {
            return .email
        }

        // Code detection (JSON, code fences, or language indicators)
        if trimmed.hasPrefix("```") {
            return .code
        }

        let unsemicolon = trimmed.hasSuffix(";")
            ? String(trimmed.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
            : trimmed

        if (unsemicolon.hasPrefix("{") && unsemicolon.hasSuffix("}")) ||
           (unsemicolon.hasPrefix("[") && unsemicolon.hasSuffix("]")) {
            return .code
        }

        if (unsemicolon.hasPrefix("\"{\\") && unsemicolon.hasSuffix("}\"")) ||
           (unsemicolon.hasPrefix("\"[{\\") && unsemicolon.hasSuffix("]\"")) {
            return .code
        }

        let codePatterns = ["func ", "def ", "class ", "import ", "var ", "let ", "const ",
                           "return ", "if (", "for (", "while (", "=>", "->", "(){", "};", "console.log"]
        for pattern in codePatterns {
            if trimmed.contains(pattern) {
                return .code
            }
        }

        // Number detection
        if Double(trimmed.replacingOccurrences(of: ",", with: "")) != nil {
            return .number
        }

        return .plainText
    }
}
