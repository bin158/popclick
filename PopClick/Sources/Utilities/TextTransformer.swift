import Foundation

/// Provides comprehensive text transformation and formatting utilities
struct TextTransformer {

    enum TransformKind: String, CaseIterable, Identifiable {
        case uppercase = "UPPERCASE"
        case lowercase = "lowercase"
        case capitalize = "Capitalize"
        case removeLineBreaks = "Remove Line Breaks"
        case trimSpaces = "Trim Spaces"
        case formatJSON = "Format JSON"
        case validateJSON = "Validate JSON"
        case formatSQL = "Format SQL"
        case urlEncode = "URL Encode"
        case urlDecode = "URL Decode"
        case base64Encode = "Base64 Encode"
        case base64Decode = "Base64 Decode"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .uppercase: return "textformat.size.larger"
            case .lowercase: return "textformat.size.smaller"
            case .capitalize: return "textformat"
            case .removeLineBreaks: return "text.alignleft"
            case .trimSpaces: return "arrow.left.and.right.text.vertical"
            case .formatJSON: return "curlybraces"
            case .validateJSON: return "checkmark.seal"
            case .formatSQL: return "cylinder.split.1x2"
            case .urlEncode: return "link.badge.plus"
            case .urlDecode: return "link"
            case .base64Encode: return "lock.shield"
            case .base64Decode: return "lock.open"
            }
        }
    }

    /// Transforms input text using the specified transformation kind
    static func transform(_ text: String, kind: TransformKind) -> String {
        switch kind {
        case .uppercase:
            return text.uppercased()

        case .lowercase:
            return text.lowercased()

        case .capitalize:
            return text.capitalized

        case .removeLineBreaks:
            return text
                .components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .joined(separator: " ")

        case .trimSpaces:
            let lines = text.components(separatedBy: .newlines)
            let trimmedLines = lines.map { $0.trimmingCharacters(in: .whitespaces) }
            return trimmedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        case .formatJSON:
            return formatJSONString(text)

        case .validateJSON:
            let result = validateJSONString(text)
            return result.message

        case .formatSQL:
            return formatSQLString(text)

        case .urlEncode:
            var allowed = CharacterSet.urlQueryAllowed
            allowed.remove(charactersIn: "+=&?#")
            return text.addingPercentEncoding(withAllowedCharacters: allowed) ?? text

        case .urlDecode:
            return text.removingPercentEncoding ?? text

        case .base64Encode:
            guard let data = text.data(using: .utf8) else { return text }
            return data.base64EncodedString()

        case .base64Decode:
            guard let data = Data(base64Encoded: text.trimmingCharacters(in: .whitespacesAndNewlines)),
                  let decoded = String(data: data, encoding: .utf8) else {
                return text
            }
            return decoded
        }
    }

    /// Robust JSON formatting with support for single quotes, code blocks, unescaped strings, trailing commas, comments, and JS objects
    static func formatJSONString(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return raw }

        // 1. Strip markdown code fences if present (```json ... ``` or ``` ... ```)
        if text.hasPrefix("```") {
            let lines = text.components(separatedBy: "\n")
            let inner = lines.filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return !trimmed.hasPrefix("```")
            }
            text = inner.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 2. Strip trailing semicolon if present (e.g. `const x = {...};` or `{...};`)
        if text.hasSuffix(";") {
            text = String(text.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 3. Unescape string if double-escaped (e.g. "{\"key\": \"value\"}")
        if text.hasPrefix("\"") && text.hasSuffix("\"") && text.contains("\\\"") {
            let unescaped = String(text.dropFirst().dropLast())
                .replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\\\", with: "\\")
            if (unescaped.hasPrefix("{") && unescaped.hasSuffix("}")) ||
               (unescaped.hasPrefix("[") && unescaped.hasSuffix("]")) {
                text = unescaped
            }
        }

        // 4. Extract JSON object or array if prefixed by variable assignment (e.g. `const config = {...}`)
        if !text.hasPrefix("{") && !text.hasPrefix("[") {
            if let firstBrace = text.firstIndex(of: "{"),
               let lastBrace = text.lastIndex(of: "}"),
               firstBrace < lastBrace {
                text = String(text[firstBrace...lastBrace]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if let firstBracket = text.firstIndex(of: "["),
                      let lastBracket = text.lastIndex(of: "]"),
                      firstBracket < lastBracket {
                text = String(text[firstBracket...lastBracket]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Helper to attempt JSONSerialization
        func trySerialize(_ candidate: String) -> String? {
            var writeOpts: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys]
            if #available(macOS 10.15, *) {
                writeOpts.insert(.withoutEscapingSlashes)
            }
            guard let data = candidate.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]),
                  (obj is NSDictionary || obj is NSArray),
                  let pretty = try? JSONSerialization.data(withJSONObject: obj, options: writeOpts),
                  let res = String(data: pretty, encoding: .utf8) else {
                return nil
            }
            return res
        }

        // Step A: Try standard serialization directly first
        if let standardResult = trySerialize(text) {
            return standardResult
        }

        // Step B: Strip comments (C-style // and /* */) while preserving URLs like "https://..."
        var sanitized = text
        if let multiLineRegex = try? NSRegularExpression(pattern: #"\/\*[\s\S]*?\*\/"#) {
            sanitized = multiLineRegex.stringByReplacingMatches(
                in: sanitized,
                range: NSRange(sanitized.startIndex..., in: sanitized),
                withTemplate: ""
            )
        }
        if let singleLineRegex = try? NSRegularExpression(pattern: #"(?m)(?<=[,\{\[\s]|^)\/\/[^\n]*"#) {
            sanitized = singleLineRegex.stringByReplacingMatches(
                in: sanitized,
                range: NSRange(sanitized.startIndex..., in: sanitized),
                withTemplate: ""
            )
        }

        if let afterComments = trySerialize(sanitized) {
            return afterComments
        }

        // Step C: Normalize Python literals & trailing commas
        sanitized = sanitized.replacingOccurrences(of: ": True", with: ": true")
                             .replacingOccurrences(of: ": False", with: ": false")
                             .replacingOccurrences(of: ": None", with: ": null")

        let trailingCommaPattern = #",(\s*[}\]])"#
        if let regex = try? NSRegularExpression(pattern: trailingCommaPattern) {
            sanitized = regex.stringByReplacingMatches(
                in: sanitized,
                range: NSRange(sanitized.startIndex..., in: sanitized),
                withTemplate: "$1"
            )
        }

        if let afterCommas = trySerialize(sanitized) {
            return afterCommas
        }

        // Step D: Normalize unquoted JS keys like `{name: "John", age: 30}` -> `{"name": "John", "age": 30}`
        let unquotedKeyPattern = #"([{,]\s*)([a-zA-Z_$][a-zA-Z0-9_$-]*)\s*:"#
        if let unquotedRegex = try? NSRegularExpression(pattern: unquotedKeyPattern) {
            sanitized = unquotedRegex.stringByReplacingMatches(
                in: sanitized,
                range: NSRange(sanitized.startIndex..., in: sanitized),
                withTemplate: "$1\"$2\":"
            )
        }

        if let afterUnquoted = trySerialize(sanitized) {
            return afterUnquoted
        }

        // Step E: Normalize single-quoted strings: `'value'` -> `"value"`
        let sqPattern = #"\'([^\'\\]*(?:\\.[^\'\\]*)*)\'"#
        if let sqRegex = try? NSRegularExpression(pattern: sqPattern) {
            sanitized = sqRegex.stringByReplacingMatches(
                in: sanitized,
                range: NSRange(sanitized.startIndex..., in: sanitized),
                withTemplate: "\"$1\""
            )
        }

        if let afterSingleQuotes = trySerialize(sanitized) {
            return afterSingleQuotes
        }

        return raw
    }

    /// Validates JSON string syntax and returns validation status message
    static func validateJSONString(_ raw: String) -> (isValid: Bool, message: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else {
            return (false, "Invalid UTF-8 Encoding")
        }
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            return (true, "Valid JSON (格式正确)")
        } catch {
            return (false, "JSON Error: \(error.localizedDescription)")
        }
    }

    /// Formats SQL with capitalized keywords and aligned major clauses
    static func formatSQLString(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return raw }

        let majorClauses = [
            "SELECT", "FROM", "WHERE", "INNER JOIN", "LEFT JOIN", "RIGHT JOIN", "FULL JOIN",
            "CROSS JOIN", "JOIN", "ON", "GROUP BY", "ORDER BY", "HAVING", "LIMIT", "OFFSET",
            "INSERT INTO", "VALUES", "UPDATE", "SET", "DELETE FROM", "UNION ALL", "UNION"
        ]

        let keywords = [
            "AND", "OR", "NOT", "IN", "IS NULL", "IS NOT NULL", "LIKE", "BETWEEN",
            "EXISTS", "AS", "DISTINCT", "CASE", "WHEN", "THEN", "ELSE", "END",
            "COUNT", "SUM", "AVG", "MIN", "MAX", "COALESCE", "ASC", "DESC",
            "BY", "INTO", "TABLE", "CREATE", "DROP", "ALTER", "PRIMARY KEY", "FOREIGN KEY"
        ]

        for kw in (majorClauses + keywords) {
            let pattern = "\\b(?i)\(kw)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern) {
                text = regex.stringByReplacingMatches(
                    in: text,
                    range: NSRange(text.startIndex..., in: text),
                    withTemplate: kw
                )
            }
        }

        for clause in majorClauses {
            if clause == "SELECT" || clause == "INSERT INTO" || clause == "UPDATE" || clause == "CREATE" {
                continue
            }
            let pattern = "\\s+\\b\(clause)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern) {
                text = regex.stringByReplacingMatches(
                    in: text,
                    range: NSRange(text.startIndex..., in: text),
                    withTemplate: "\n\(clause)"
                )
            }
        }

        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return lines.joined(separator: "\n")
    }

    /// Computes basic statistics on text
    static func statistics(for text: String) -> (words: Int, characters: Int, lines: Int) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return (0, 0, 0) }

        let characters = text.count
        let lines = text.components(separatedBy: .newlines).count

        let words: Int
        let tokenizer = CFStringTokenizerCreate(
            kCFAllocatorDefault,
            text as CFString,
            CFRangeMake(0, CFStringGetLength(text as CFString)),
            kCFStringTokenizerUnitWord,
            CFLocaleCopyCurrent()
        )
        var count = 0
        while CFStringTokenizerAdvanceToNextToken(tokenizer) != [] {
            count += 1
        }
        words = max(count, text.split { $0.isWhitespace }.count)

        return (words, characters, lines)
    }
}
