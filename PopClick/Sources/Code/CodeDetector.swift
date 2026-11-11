import Foundation

/// Fast, high-accuracy source code detector and programming language classifier
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
        if trimmed.isEmpty {
            return DetectionResult(isCode: false, language: .generic, confidence: 0)
        }

        // 1. Check if enclosed in Markdown code fences (e.g. ```swift ... ```)
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

        // 2. Check File Extension from context (e.g. ".swift", ".py", ".rs")
        if let ext = fileExtension?.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")) {
            for lang in CodeLanguage.allCases {
                if lang.fileExtensions.contains(ext) {
                    return DetectionResult(isCode: true, language: lang, confidence: 0.95)
                }
            }
        }

        // 3. Check Shebang (e.g. #!/usr/bin/env python3, #!/bin/bash)
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
        }

        // 4. Check JSON
        if isLikelyJSON(trimmed) {
            return DetectionResult(isCode: true, language: .json, confidence: 0.95)
        }

        // 5. Check SQL
        if isLikelySQL(trimmed) {
            return DetectionResult(isCode: true, language: .sql, confidence: 0.92)
        }

        // 6. Check HTML / XML
        if isLikelyHTML(trimmed) {
            return DetectionResult(isCode: true, language: .html, confidence: 0.90)
        }

        // 7. Check CSS
        if isLikelyCSS(trimmed) {
            return DetectionResult(isCode: true, language: .css, confidence: 0.88)
        }

        // 8. Keyword-based language scoring
        var languageScores: [CodeLanguage: Double] = [:]

        // Swift
        let swiftKeywords = ["func ", "guard let ", "import SwiftUI", "import AppKit", "struct ", "extension ", "var body: some View", "@State", "@Binding", "@ObservedObject", "fatalError("]
        scoreLanguage(.swift, keywords: swiftKeywords, in: trimmed, scores: &languageScores, weight: 2.0)

        // Python
        let pythonKeywords = ["def ", "elif ", "__init__", "import ", "from ", "class ", "print(", "self.", "lambda ", "except Exception", "is None"]
        scoreLanguage(.python, keywords: pythonKeywords, in: trimmed, scores: &languageScores, weight: 1.8)

        // Rust
        let rustKeywords = ["fn ", "let mut ", "impl ", "pub struct ", "pub fn ", "println!", "match ", "Option<", "Result<", "unwrap()"]
        scoreLanguage(.rust, keywords: rustKeywords, in: trimmed, scores: &languageScores, weight: 2.2)

        // Go
        let goKeywords = ["package ", "func ", "fmt.Println", "fmt.Printf", "type ", "struct {", "go func()", "chan ", "nil", "err != nil"]
        scoreLanguage(.go, keywords: goKeywords, in: trimmed, scores: &languageScores, weight: 2.0)

        // TypeScript
        let tsKeywords = ["interface ", "type ", "export const ", "export function ", "as const", ": string", ": number", ": boolean", ": Promise<", "<T>"]
        scoreLanguage(.typescript, keywords: tsKeywords, in: trimmed, scores: &languageScores, weight: 2.0)

        // JavaScript
        let jsKeywords = ["const ", "let ", "var ", "function ", "console.log", "document.", "window.", "require(", "module.exports", "=>"]
        scoreLanguage(.javascript, keywords: jsKeywords, in: trimmed, scores: &languageScores, weight: 1.5)

        // Java
        let javaKeywords = ["public static void main", "System.out.println", "public class ", "private final ", "package ", "@Override", "throws Exception"]
        scoreLanguage(.java, keywords: javaKeywords, in: trimmed, scores: &languageScores, weight: 2.2)

        // C / C++
        let cppKeywords = ["#include <", "std::cout", "std::cin", "std::vector", "int main(", "nullptr", "printf(", "cout <<", "namespace std"]
        scoreLanguage(.cpp, keywords: cppKeywords, in: trimmed, scores: &languageScores, weight: 2.2)

        // C#
        let csharpKeywords = ["using System;", "namespace ", "Console.WriteLine", "public async Task", "public class ", "get; set;"]
        scoreLanguage(.csharp, keywords: csharpKeywords, in: trimmed, scores: &languageScores, weight: 2.2)

        // Dart
        let dartKeywords = ["Widget build(", "BuildContext ", "StatelessWidget", "StatefulWidget", "void main()", "setState("]
        scoreLanguage(.dart, keywords: dartKeywords, in: trimmed, scores: &languageScores, weight: 2.5)

        // PHP
        let phpKeywords = ["<?php", "$this->", "function ", "echo ", "public function ", "foreach ($"]
        scoreLanguage(.php, keywords: phpKeywords, in: trimmed, scores: &languageScores, weight: 2.2)

        // YAML
        let yamlKeywords = ["---", "apiVersion:", "metadata:", "spec:", "services:", "version:"]
        scoreLanguage(.yaml, keywords: yamlKeywords, in: trimmed, scores: &languageScores, weight: 2.0)

        // Shell
        let shellKeywords = ["echo ", "chmod ", "grep ", "export ", "if [ ", "fi", "done", "source ", "curl -"]
        scoreLanguage(.shell, keywords: shellKeywords, in: trimmed, scores: &languageScores, weight: 1.8)

        // Find highest scoring language
        if let top = languageScores.max(by: { $0.value < $1.value }), top.value >= 2.0 {
            let conf = min(0.95, 0.5 + top.value * 0.1)
            return DetectionResult(isCode: true, language: top.key, confidence: conf)
        }

        // 9. Generic code heuristics (braces, operators, semicolons, function calls)
        let isGenericCode = checkGenericCodeHeuristics(trimmed)
        if isGenericCode {
            return DetectionResult(isCode: true, language: .generic, confidence: 0.70)
        }

        return DetectionResult(isCode: false, language: .generic, confidence: 0)
    }

    // MARK: - Private Helpers

    private static func scoreLanguage(
        _ lang: CodeLanguage,
        keywords: [String],
        in text: String,
        scores: inout [CodeLanguage: Double],
        weight: Double
    ) {
        var matchCount = 0.0
        for kw in keywords {
            if text.contains(kw) {
                matchCount += 1.0
            }
        }
        if matchCount > 0 {
            scores[lang] = matchCount * weight
        }
    }

    private static func isLikelyJSON(_ s: String) -> Bool {
        if (s.hasPrefix("{") && s.hasSuffix("}")) || (s.hasPrefix("[") && s.hasSuffix("]")) {
            if s.contains("\":") || s.contains("\",") || s.contains("\": ") {
                return true
            }
            if let data = s.data(using: .utf8),
               (try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])) != nil {
                return true
            }
        }
        return false
    }

    private static func isLikelySQL(_ s: String) -> Bool {
        let upper = s.uppercased()
        let sqlKeywords = ["SELECT ", "INSERT INTO ", "UPDATE ", "DELETE FROM ", "CREATE TABLE ", "ALTER TABLE ", "DROP TABLE "]
        for kw in sqlKeywords {
            if upper.contains(kw) {
                if upper.contains(" FROM ") || upper.contains(" WHERE ") || upper.contains(" VALUES") || upper.contains(" SET ") || upper.contains(" JOIN ") {
                    return true
                }
            }
        }
        return false
    }

    private static func isLikelyHTML(_ s: String) -> Bool {
        let lower = s.lowercased()
        if lower.hasPrefix("<!doctype") || lower.hasPrefix("<html") {
            return true
        }
        let tags = ["<div", "<span", "<p>", "<a href", "<button", "<input", "</div>", "</span>", "</p>"]
        var count = 0
        for tag in tags {
            if lower.contains(tag) { count += 1 }
        }
        return count >= 2
    }

    private static func isLikelyCSS(_ s: String) -> Bool {
        if s.contains("{") && s.contains("}") && s.contains(":") && s.contains(";") {
            let cssProps = ["margin:", "padding:", "color:", "display:", "background:", "font-size:", "border:", "flex", "grid"]
            var count = 0
            for prop in cssProps {
                if s.contains(prop) { count += 1 }
            }
            return count >= 2
        }
        return false
    }

    private static func checkGenericCodeHeuristics(_ s: String) -> Bool {
        var score = 0
        if s.contains("{") && s.contains("}") { score += 2 }
        if s.contains(";") && s.contains("\n") { score += 2 }
        if s.contains("->") || s.contains("=>") { score += 2 }
        if s.contains("==") || s.contains("!=") || s.contains("&&") || s.contains("||") { score += 2 }
        if s.contains("//") || s.contains("/*") || s.contains("*/") { score += 1 }
        if s.contains("func ") || s.contains("def ") || s.contains("var ") || s.contains("let ") || s.contains("const ") { score += 3 }

        return score >= 4
    }
}
