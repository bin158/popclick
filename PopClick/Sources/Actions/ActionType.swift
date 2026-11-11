import Foundation

/// Available action types for PopClick toolbar and popovers
enum ActionType: String, Identifiable, CaseIterable {
    // Primary Actions
    case copy
    case search
    case translate
    case ai
    case define
    case speak
    case share

    // Contextual / URL Actions
    case openURL
    case email

    // Code Intelligence Actions
    case codeExplain
    case codeComment
    case codeDoc
    case codeFix
    case codeRefactor
    case codeOptimize
    case codeTest
    case codeSecurity
    case formatCode

    // Specialized Data Formats
    case formatJSON
    case validateJSON
    case formatSQL

    // Text Utility Actions
    case uppercase
    case lowercase
    case capitalize
    case removeLineBreaks
    case trimSpaces
    case urlEncode
    case base64Encode

    // Overflow
    case more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .copy: return "Copy"
        case .search: return "Search"
        case .translate: return "Translate"
        case .ai: return "AI"
        case .define: return "Define"
        case .speak: return "Speak"
        case .share: return "Share"
        case .openURL: return "Open"
        case .email: return "Email"
        case .codeExplain: return "Explain"
        case .codeComment: return "Comment"
        case .codeDoc: return "Doc"
        case .codeFix: return "Fix"
        case .codeRefactor: return "Refactor"
        case .codeOptimize: return "Optimize"
        case .codeTest: return "Test"
        case .codeSecurity: return "Security"
        case .formatCode: return "Format"
        case .formatJSON: return "Format"
        case .validateJSON: return "Validate"
        case .formatSQL: return "Format"
        case .uppercase: return "UPPER"
        case .lowercase: return "lower"
        case .capitalize: return "Title"
        case .removeLineBreaks: return "Unwrap"
        case .trimSpaces: return "Trim"
        case .urlEncode: return "Encode"
        case .base64Encode: return "Base64"
        case .more: return "More"
        }
    }

    var iconName: String {
        switch self {
        case .copy: return "doc.on.doc"
        case .search: return "magnifyingglass"
        case .translate: return "character.book.closed"
        case .ai: return "sparkles"
        case .define: return "text.book.closed"
        case .speak: return "speaker.wave.2"
        case .share: return "square.and.arrow.up"
        case .openURL: return "arrow.up.right.square"
        case .email: return "envelope"
        case .codeExplain: return "lightbulb"
        case .codeComment: return "text.bubble"
        case .codeDoc: return "doc.text"
        case .codeFix: return "wrench.and.screwdriver"
        case .codeRefactor: return "arrow.triangle.branch"
        case .codeOptimize: return "bolt.fill"
        case .codeTest: return "flask"
        case .codeSecurity: return "shield.checkerboard"
        case .formatCode: return "text.alignleft"
        case .formatJSON: return "curlybraces"
        case .validateJSON: return "checkmark.seal"
        case .formatSQL: return "cylinder.split.1x2"
        case .uppercase: return "textformat.size.larger"
        case .lowercase: return "textformat.size.smaller"
        case .capitalize: return "textformat"
        case .removeLineBreaks: return "text.alignleft"
        case .trimSpaces: return "arrow.left.and.right.text.vertical"
        case .urlEncode: return "link.badge.plus"
        case .base64Encode: return "lock.shield"
        case .more: return "ellipsis"
        }
    }

    var shortcutHint: String? {
        switch self {
        case .copy: return "⌘C"
        case .search: return "⌘F"
        case .ai: return "⌘J"
        case .codeExplain: return "⌘E"
        default: return nil
        }
    }
}
