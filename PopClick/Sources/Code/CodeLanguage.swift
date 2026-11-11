import Foundation

/// Comprehensive enumeration of supported programming and markup languages
public enum CodeLanguage: String, CaseIterable, Identifiable, Codable {
    case swift = "Swift"
    case java = "Java"
    case python = "Python"
    case cpp = "C/C++"
    case csharp = "C#"
    case javascript = "JavaScript"
    case typescript = "TypeScript"
    case rust = "Rust"
    case go = "Go"
    case dart = "Dart"
    case php = "PHP"
    case sql = "SQL"
    case html = "HTML"
    case css = "CSS"
    case json = "JSON"
    case yaml = "YAML"
    case shell = "Shell"
    case generic = "Code"

    public var id: String { rawValue }

    public var displayName: String { rawValue }

    /// Identifier used by Highlight.js
    public var highlightKey: String {
        switch self {
        case .swift: return "swift"
        case .java: return "java"
        case .python: return "python"
        case .cpp: return "cpp"
        case .csharp: return "csharp"
        case .javascript: return "javascript"
        case .typescript: return "typescript"
        case .rust: return "rust"
        case .go: return "go"
        case .dart: return "dart"
        case .php: return "php"
        case .sql: return "sql"
        case .html: return "html"
        case .css: return "css"
        case .json: return "json"
        case .yaml: return "yaml"
        case .shell: return "bash"
        case .generic: return "code"
        }
    }

    /// File extensions associated with this language
    public var fileExtensions: [String] {
        switch self {
        case .swift: return ["swift"]
        case .java: return ["java"]
        case .python: return ["py", "pyw", "ipynb"]
        case .cpp: return ["cpp", "c", "cc", "cxx", "h", "hpp", "hxx"]
        case .csharp: return ["cs"]
        case .javascript: return ["js", "mjs", "cjs", "jsx"]
        case .typescript: return ["ts", "mts", "cts", "tsx"]
        case .rust: return ["rs"]
        case .go: return ["go"]
        case .dart: return ["dart"]
        case .php: return ["php", "phtml"]
        case .sql: return ["sql"]
        case .html: return ["html", "htm"]
        case .css: return ["css", "scss", "sass", "less"]
        case .json: return ["json"]
        case .yaml: return ["yaml", "yml"]
        case .shell: return ["sh", "bash", "zsh", "fish"]
        case .generic: return []
        }
    }

    // MARK: - Comment Syntaxes

    public var lineCommentPrefix: String {
        switch self {
        case .python, .shell, .yaml:
            return "#"
        case .sql:
            return "--"
        case .html:
            return "<!--"
        case .css:
            return "/*"
        default:
            return "//"
        }
    }

    public var blockCommentDelimiters: (start: String, end: String) {
        switch self {
        case .python:
            return (start: "\"\"\"", end: "\"\"\"")
        case .html:
            return (start: "<!--", end: "-->")
        case .sql:
            return (start: "/*", end: "*/")
        case .shell:
            return (start: ": <<'COMMENT'", end: "COMMENT")
        default:
            return (start: "/*", end: "*/")
        }
    }

    public var docCommentDelimiters: (start: String, end: String, linePrefix: String) {
        switch self {
        case .swift, .rust, .csharp, .dart:
            return (start: "", end: "", linePrefix: "///")
        case .python:
            return (start: "\"\"\"", end: "\"\"\"", linePrefix: "")
        case .java, .javascript, .typescript, .cpp, .php:
            return (start: "/**", end: " */", linePrefix: " *")
        case .sql:
            return (start: "--", end: "", linePrefix: "--")
        case .html:
            return (start: "<!--", end: "-->", linePrefix: "")
        default:
            return (start: "/**", end: " */", linePrefix: " *")
        }
    }

    // MARK: - Comment Formatting Helpers

    /// Formats code with language-specific line comments
    public func applyLineComment(to code: String) -> String {
        let prefix = lineCommentPrefix
        if self == .html {
            return "<!-- \(code) -->"
        } else if self == .css {
            return "/* \(code) */"
        }

        let lines = code.components(separatedBy: "\n")
        return lines.map { "\(prefix) \($0)" }.joined(separator: "\n")
    }

    /// Formats code with language-specific block comments
    public func applyBlockComment(to code: String) -> String {
        let (start, end) = blockCommentDelimiters
        return "\(start)\n\(code)\n\(end)"
    }

    /// Formats documentation comment for code
    public func applyDocComment(description: String, to code: String) -> String {
        let (start, end, linePrefix) = docCommentDelimiters
        var docLines: [String] = []

        if !start.isEmpty {
            docLines.append(start)
        }

        let descLines = description.components(separatedBy: "\n")
        for line in descLines {
            if linePrefix.isEmpty {
                docLines.append(line)
            } else {
                docLines.append("\(linePrefix) \(line)")
            }
        }

        if !end.isEmpty {
            docLines.append(end)
        }

        let docBlock = docLines.joined(separator: "\n")
        return "\(docBlock)\n\(code)"
    }
}
