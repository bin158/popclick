import Foundation

/// Represents a detected text selection with its content, geometry, and contextual semantics
struct TextSelection {
    let text: String
    let bounds: CGRect           // Screen coordinates of the selection (Cocoa bottom-left origin)
    let mouseLocation: CGPoint   // Mouse position at time of selection
    let contentType: ContentType
    let codeContext: CodeContext?

    init(
        text: String,
        bounds: CGRect,
        mouseLocation: CGPoint,
        contentType: ContentType,
        codeContext: CodeContext? = nil
    ) {
        self.text = text
        self.bounds = bounds
        self.mouseLocation = mouseLocation
        self.contentType = contentType
        self.codeContext = codeContext ?? contentType.codeContext
    }

    /// Detected type of selected content with specialized action sets
    enum ContentType {
        case plainText
        case url
        case email
        case code(language: CodeLanguage, context: CodeContext)
        case json(context: CodeContext)
        case sql(context: CodeContext)
        case number

        var suggestedActions: [ActionType] {
            switch self {
            case .plainText:
                return [.copy, .search, .translate, .ai, .more]
            case .code:
                return [.copy, .codeExplain, .codeComment, .codeFix, .codeRefactor, .ai, .more]
            case .json:
                return [.copy, .formatJSON, .validateJSON, .codeExplain, .ai]
            case .sql:
                return [.copy, .formatSQL, .codeExplain, .codeOptimize, .ai]
            case .url:
                return [.openURL, .copy, .share, .ai, .more]
            case .email:
                return [.email, .copy, .ai, .more]
            case .number:
                return [.copy, .search, .ai, .more]
            }
        }

        var codeContext: CodeContext? {
            switch self {
            case .code(_, let ctx), .json(let ctx), .sql(let ctx):
                return ctx
            default:
                return nil
            }
        }
    }

    /// Detect content type from text and optional accessibility context
    static func detectContentType(_ text: String, context: CodeContext? = nil) -> ContentType {
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

        // Run CodeDetector with application and file extension context
        let detection = CodeDetector.detect(
            text: trimmed,
            fileExtension: context?.fileExtension,
            appName: context?.appName
        )

        var ctx = context ?? CodeContext(
            selectedCode: text,
            isCode: detection.isCode,
            detectedLanguage: detection.language
        )
        ctx.isCode = detection.isCode
        ctx.detectedLanguage = detection.language

        if detection.isCode {
            switch detection.language {
            case .json:
                return .json(context: ctx)
            case .sql:
                return .sql(context: ctx)
            default:
                return .code(language: detection.language, context: ctx)
            }
        }

        // Number detection
        if Double(trimmed.replacingOccurrences(of: ",", with: "")) != nil {
            return .number
        }

        return .plainText
    }
}
