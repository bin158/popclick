import Foundation

/// Fast, high-accuracy source code detector and programming language classifier
/// Prioritizes precision to strictly avoid classifying natural language prose as code.
public struct CodeDetector {

    public struct DetectionResult {
        public let isCode: Bool
        public let language: CodeLanguage
        public let confidence: Double
    }

    /// Primary detection entry point
    public static func detect(
        text: String,
        fileExtension: String? = nil,
        appName: String? = nil
    ) -> DetectionResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.count < 3 {
            return DetectionResult(isCode: false, language: .generic, confidence: 0)
        }

        // =========================================================================
        // 1. FAST NEGATIVE CHECKS: Natural Language & Prose Disqualifiers
        // =========================================================================

        // A. CJK / Han Script: If text contains Chinese characters and NO explicit code syntax,
        // it is natural language prose (articles, chats, comments, documentation).
        let hasChinese = trimmed.range(of: "\\p{Han}", options: .regularExpression) != nil
        if hasChinese && !containsExplicitCodeSyntax(trimmed) {
            return DetectionResult(isCode: false, language: .generic, confidence: 0)
        }

        // B. Pure Natural Language Sentences (English or other Western prose):
        // If the text looks like standard sentences ending in punctuation with zero code symbols
        if isNaturalLanguageProse(trimmed) {
            return DetectionResult(isCode: false, language: .generic, confidence: 0)
        }

        // =========================================================================
        // 2. FAST POSITIVE CHECKS: Explicit Fences, Shebangs, JSON, SQL
        // =========================================================================

        // A. Markdown code fences (e.g. ```swift ... ```)
        if trimmed.hasPrefix("```") {
            let firstLine = trimmed.components(separatedBy: .newlines).first ?? ""
            let tag = firstLine.trimmingCharacters(in: CharacterSet(charactersIn: "`")).trimmingCharacters(in: .whitespaces).lowercased()
            for lang in CodeLanguage.allCases {
                if lang.highlightKey.lowercased() == tag || lang.rawValue.lowercased() == tag {
                    return DetectionResult(isCode: true, language: lang, confidence: 1.0)
                }
            }
            return DetectionResult(isCode: true, language: .generic, confidence: 0.95)
        }

        // B. Shebang line
        if trimmed.hasPrefix("#!") {
            let firstLine = trimmed.components(separatedBy: .newlines).first?.lowercased() ?? ""
            if firstLine.contains("python") {
                return DetectionResult(isCode: true, language: .python, confidence: 0.95)
            } else if firstLine.contains("bash") || firstLine.contains("sh") || firstLine.contains("zsh") {
                return DetectionResult(isCode: true, language: .shell, confidence: 0.95)
            } else if firstLine.contains("node") {
                return DetectionResult(isCode: true, language: .javascript, confidence: 0.95)
            } else if firstLine.contains("php") {
                return DetectionResult(isCode: true, language: .php, confidence: 0.95)
            }
            return DetectionResult(isCode: true, language: .shell, confidence: 0.90)
        }

        // C. JSON (Strictly structured key-value objects or arrays)
        if isStrictJSON(trimmed) {
            return DetectionResult(isCode: true, language: .json, confidence: 0.95)
        }

        // D. SQL (Structured DML/DDL queries with valid SQL syntax)
        if isStrictSQL(trimmed) {
            return DetectionResult(isCode: true, language: .sql, confidence: 0.92)
        }

        // E. HTML / XML markup
        if isStrictHTML(trimmed) {
            return DetectionResult(isCode: true, language: .html, confidence: 0.90)
        }

        // F. CSS stylesheets
        if isStrictCSS(trimmed) {
            return DetectionResult(isCode: true, language: .css, confidence: 0.88)
        }

        // =========================================================================
        // 3. CODE SYNTAX STRUCTURAL ANALYSIS (Regex with word boundaries)
        // =========================================================================

        let codeScore = evaluateCodeStructuralScore(trimmed)

        // If the text does not exhibit sufficient coding structure, it's NOT code!
        if codeScore < 2.0 {
            return DetectionResult(isCode: false, language: .generic, confidence: 0)
        }

        // =========================================================================
        // 4. LANGUAGE CLASSIFICATION (For validated code)
        // =========================================================================

        // If file extension is present and matches a known language, use it to refine
        if let ext = fileExtension?.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")) {
            for lang in CodeLanguage.allCases {
                if lang.fileExtensions.contains(ext) {
                    return DetectionResult(isCode: true, language: lang, confidence: 0.95)
                }
            }
        }

        // Analyze specific language grammar
        let classifiedLanguage = classifyLanguageByGrammar(trimmed)
        return DetectionResult(isCode: true, language: classifiedLanguage, confidence: 0.85)
    }

    // MARK: - Natural Language & Disqualification Heuristics

    /// Detects if text is predominantly natural language prose
    private static func isNaturalLanguageProse(_ s: String) -> Bool {
        // If it contains typical code symbols, it's not pure prose
        let codeSymbols = ["{", "}", ";", "->", "=>", "::", "!=", "==", "===", "&&", "||", "++", "+=", "/*", "*/", "<?php"]
        for sym in codeSymbols {
            if s.contains(sym) {
                return false
            }
        }

        // Single line without code operators
        let lines = s.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if lines.count == 1 {
            let line = lines[0]
            // If it has spaces between words, starts with capital or normal word, and has no assignment or function call
            if !line.contains("=") && !line.contains("(") && !line.contains(")") && !line.contains("<") && !line.contains(">") {
                return true
            }
            // English sentence with ending punctuation
            if (line.hasSuffix(".") || line.hasSuffix("!") || line.hasSuffix("?")) && !line.contains("=") {
                return true
            }
        }

        // Paragraph with standard punctuation and high word ratio
        let words = s.components(separatedBy: CharacterSet.whitespacesAndNewlines).filter { !$0.isEmpty }
        if words.count >= 4 && !s.contains("=") && !s.contains(";") && !s.contains("{") {
            let punctuationCount = s.filter { [".", ",", "!", "?", "'", "\"", "-"].contains(String($0)) }.count
            if Double(punctuationCount) / Double(max(1, words.count)) > 0.15 {
                return true
            }
        }

        return false
    }

    /// Checks if text with Chinese contains real code syntax constructs
    private static func containsExplicitCodeSyntax(_ s: String) -> Bool {
        let codePatterns = [
            #"//.*"#,                              // Single line comment
            #"/\*[\s\S]*?\*/"#,                   // Block comment
            #"\b(func|def|fn|function|var|let|const|class|struct|interface|enum)\s+[A-Za-z_]"#, // Declaration
            #"\b(import|export|return|package|#include)\s+"#,                                   // Directives
            #"[{};]\s*$"#,                         // Trailing brace or semicolon
            #"[a-zA-Z_]\w*\s*\(.*?\)"#             // Function call
        ]

        for p in codePatterns {
            if s.range(of: p, options: .regularExpression) != nil {
                return true
            }
        }
        return false
    }

    // MARK: - Strict Format Checkers

    /// Validates strictly formatted JSON (must have key-value pairs or structured arrays)
    private static func isStrictJSON(_ s: String) -> Bool {
        guard (s.hasPrefix("{") && s.hasSuffix("}")) || (s.hasPrefix("[") && s.hasSuffix("]")) else {
            return false
        }

        // Must have quoted keys or structured format, not just [citation] or {placeholder}
        let hasJSONKeys = s.range(of: #""[\w-]+"\s*:"#, options: .regularExpression) != nil
        if hasJSONKeys {
            if let data = s.data(using: .utf8),
               (try? JSONSerialization.jsonObject(with: data)) != nil {
                return true
            }
        }

        // Array of objects or multiple literals
        if s.hasPrefix("[") && s.hasSuffix("]") && s.contains(",") {
            if let data = s.data(using: .utf8),
               (try? JSONSerialization.jsonObject(with: data)) != nil {
                return true
            }
        }

        return false
    }

    /// Validates strictly structured SQL queries
    private static func isStrictSQL(_ s: String) -> Bool {
        let sqlPatterns = [
            #"(?i)\bSELECT\s+[\w*,\s()]+\s+FROM\s+[\w.]+(\s+(WHERE|GROUP\s+BY|ORDER\s+BY|HAVING|LIMIT|JOIN|INNER\s+JOIN|LEFT\s+JOIN)\b)?"#,
            #"(?i)\bINSERT\s+INTO\s+[\w.]+\s*(\(.*?\))?\s*VALUES"#,
            #"(?i)\bUPDATE\s+[\w.]+\s+SET\s+[\w.]+\s*="#,
            #"(?i)\bDELETE\s+FROM\s+[\w.]+\s+WHERE"#,
            #"(?i)\b(CREATE|ALTER|DROP)\s+TABLE\s+[\w.]+"#
        ]

        for pattern in sqlPatterns {
            if s.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        return false
    }

    /// Validates strictly structured HTML/XML
    private static func isStrictHTML(_ s: String) -> Bool {
        let lower = s.lowercased()
        if lower.hasPrefix("<!doctype html") || lower.hasPrefix("<html") {
            return true
        }

        // Requires matching tags or multiple standard elements
        let tagPairPattern = #"<([a-zA-Z0-9_-]+)(\s+[^>]*)?>[\s\S]*?</\1>"#
        if s.range(of: tagPairPattern, options: .regularExpression) != nil {
            return true
        }

        return false
    }

    /// Validates strictly structured CSS
    private static func isStrictCSS(_ s: String) -> Bool {
        let cssRulePattern = #"(?s)[.#]?[a-zA-Z0-9_-]+(\s*,\s*[.#]?[a-zA-Z0-9_-]+)*\s*\{\s*([a-zA-Z-]+:\s*[^;}]+;?\s*)+\}"#
        return s.range(of: cssRulePattern, options: .regularExpression) != nil
    }

    // MARK: - Code Structural Evaluation

    /// Scores code structural weight using precise syntax patterns
    private static func evaluateCodeStructuralScore(_ s: String) -> Double {
        var score = 0.0

        // 1. Function / Method declarations (+3.0)
        let fnPattern = #"\b(func|def|fn|function)\s+[A-Za-z_]\w*\s*(<.*?>)?\s*\(.*?\)"#
        if s.range(of: fnPattern, options: .regularExpression) != nil {
            score += 3.0
        }

        // Typed method in Java/C++/C# (+3.0)
        let typedMethodPattern = #"\b(public|private|protected)\s+(static\s+)?(void|int|double|bool|String|[A-Z]\w+)\s+[A-Za-z_]\w*\s*\(.*?\)"#
        if s.range(of: typedMethodPattern, options: .regularExpression) != nil {
            score += 3.0
        }

        // 2. Variable / Constant declarations with assignment (+2.5)
        let varPattern = #"\b(let|var|const|val)\s+[A-Za-z_]\w*\s*(:\s*[\w<>\[\]?, ]+)?\s*="#
        if s.range(of: varPattern, options: .regularExpression) != nil {
            score += 2.5
        }

        // 3. Class / Struct / Interface / Enum (+2.5)
        let typePattern = #"\b(class|struct|interface|enum|protocol|trait|impl)\s+[A-Z]\w*"#
        if s.range(of: typePattern, options: .regularExpression) != nil {
            score += 2.5
        }

        // 4. Import / Package / Include statements (+2.5)
        let importPattern = #"\b(import\s+[A-Za-z0-9_.]+|from\s+[\w.]+\s+import|#include\s*[<"]|using\s+System|package\s+[\w.]+;)"#
        if s.range(of: importPattern, options: .regularExpression) != nil {
            score += 2.5
        }

        // 5. Control Flow with code syntax (+2.0)
        let controlPattern = #"\b(guard\s+let\b|if\s*\(.*?\)\s*\{|for\s*\(.*?;.*?;.*?\)|while\s*\(.*?\)\s*\{|switch\s*\(.*?\)\s*\{)"#
        if s.range(of: controlPattern, options: .regularExpression) != nil {
            score += 2.0
        }

        // 6. Return statement with value (+1.5)
        let returnPattern = #"\breturn\s+[^;]+[;]?"#
        if s.range(of: returnPattern, options: .regularExpression) != nil {
            score += 1.5
        }

        // 7. Code operators (+1.0)
        let operatorPattern = #"(\-\>|\=\>|\:\:|\=\=\=|\!\=\=|\=\=|\!\=|\&\&|\|\||\?\?|\+\=|\-\=)"#
        if s.range(of: operatorPattern, options: .regularExpression) != nil {
            score += 1.0
        }

        // 8. Semicolon at line endings (+1.0)
        if s.contains(";\n") || s.hasSuffix(";") {
            score += 1.0
        }

        // 9. Multiline braced block (+1.5)
        if s.contains("{") && s.contains("}") && s.contains("\n") {
            score += 1.5
        }

        return score
    }

    // MARK: - Language Grammar Classifier

    private static func classifyLanguageByGrammar(_ s: String) -> CodeLanguage {
        // Swift
        if s.contains("func ") && (s.contains("->") || s.contains("guard let") || s.contains("some View")) {
            return .swift
        }
        if s.contains("import SwiftUI") || s.contains("import AppKit") || s.contains("import Foundation") {
            return .swift
        }

        // Python
        if s.contains("def ") && s.contains(":") {
            return .python
        }
        if s.contains("import ") && s.contains("from ") {
            return .python
        }
        if s.contains("__init__") || s.contains("self.") || s.contains("elif ") {
            return .python
        }

        // Rust
        if s.contains("fn ") && (s.contains("let mut ") || s.contains("->") || s.contains("impl ") || s.contains("pub fn ")) {
            return .rust
        }
        if s.contains("println!") || s.contains("unwrap()") {
            return .rust
        }

        // Go
        if s.contains("package ") && s.contains("func ") {
            return .go
        }
        if s.contains("fmt.Println") || s.contains("err != nil") {
            return .go
        }

        // TypeScript / JavaScript
        if s.contains("interface ") || s.contains(": string") || s.contains(": number") || s.contains("as const") {
            return .typescript
        }
        if s.contains("const ") || s.contains("console.log") || s.contains("document.") {
            return .javascript
        }

        // Java
        if s.contains("public static void main") || s.contains("System.out.println") || s.contains("@Override") {
            return .java
        }

        // C / C++
        if s.contains("#include <") || s.contains("std::cout") || s.contains("nullptr") {
            return .cpp
        }

        // C#
        if s.contains("using System;") || s.contains("Console.WriteLine") || s.contains("public async Task") {
            return .csharp
        }

        // Dart
        if s.contains("Widget build(") || s.contains("BuildContext ") {
            return .dart
        }

        // PHP
        if s.contains("<?php") || s.contains("$this->") {
            return .php
        }

        // Shell
        if s.contains("chmod ") || s.contains("grep ") || s.contains("export ") || s.contains("curl -") {
            return .shell
        }

        // YAML
        if s.contains("apiVersion:") || s.contains("metadata:") {
            return .yaml
        }

        return .generic
    }
}
