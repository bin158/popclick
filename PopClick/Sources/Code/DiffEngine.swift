import Foundation

/// Represents a single line in a computed diff
public struct DiffLine: Identifiable, Equatable {
    public let id = UUID()

    public enum Kind: Equatable {
        case unchanged
        case added
        case deleted
    }

    public let kind: Kind
    public let oldLineNumber: Int?
    public let newLineNumber: Int?
    public let text: String

    public init(kind: Kind, oldLineNumber: Int?, newLineNumber: Int?, text: String) {
        self.kind = kind
        self.oldLineNumber = oldLineNumber
        self.newLineNumber = newLineNumber
        self.text = text
    }
}

/// Computed diff result containing diff lines and summary statistics
public struct DiffResult: Equatable {
    public let lines: [DiffLine]
    public let addedCount: Int
    public let deletedCount: Int
    public let hasChanges: Bool

    public init(lines: [DiffLine]) {
        self.lines = lines
        self.addedCount = lines.filter { $0.kind == .added }.count
        self.deletedCount = lines.filter { $0.kind == .deleted }.count
        self.hasChanges = addedCount > 0 || deletedCount > 0
    }
}

/// High-performance LCS line-by-line diff engine with code block extractor
public struct DiffEngine {

    /// Computes unified line-by-line diff between original text and modified text
    public static func computeDiff(original: String, modified: String) -> DiffResult {
        let origLines = original.components(separatedBy: .newlines)
        let modLines = modified.components(separatedBy: .newlines)

        let n = origLines.count
        let m = modLines.count

        // Guard against massive buffers
        if n > 800 || m > 800 {
            return computeSimpleFallbackDiff(orig: origLines, mod: modLines)
        }

        var dp = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in 0..<n {
            for j in 0..<m {
                if origLines[i] == modLines[j] {
                    dp[i + 1][j + 1] = dp[i][j] + 1
                } else {
                    dp[i + 1][j + 1] = max(dp[i + 1][j], dp[i][j + 1])
                }
            }
        }

        var i = n
        var j = m
        var reversedDiff: [DiffLine] = []

        while i > 0 || j > 0 {
            if i > 0 && j > 0 && origLines[i - 1] == modLines[j - 1] {
                reversedDiff.append(DiffLine(kind: .unchanged, oldLineNumber: i, newLineNumber: j, text: origLines[i - 1]))
                i -= 1
                j -= 1
            } else if j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j]) {
                reversedDiff.append(DiffLine(kind: .added, oldLineNumber: nil, newLineNumber: j, text: modLines[j - 1]))
                j -= 1
            } else if i > 0 && (j == 0 || dp[i][j - 1] < dp[i - 1][j]) {
                reversedDiff.append(DiffLine(kind: .deleted, oldLineNumber: i, newLineNumber: nil, text: origLines[i - 1]))
                i -= 1
            }
        }

        return DiffResult(lines: reversedDiff.reversed())
    }

    /// Extracts clean code snippet from AI markdown response
    public static func extractCode(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Look for ```code blocks
        let pattern = #"```(?:[a-zA-Z0-9_-]+)?\n([\s\S]*?)```"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           let range = Range(match.range(at: 1), in: trimmed) {
            let extracted = String(trimmed[range]).trimmingCharacters(in: .newlines)
            if !extracted.isEmpty {
                return extracted
            }
        }

        // 2. If no code blocks found, check if text itself looks like code
        return trimmed
    }

    private static func computeSimpleFallbackDiff(orig: [String], mod: [String]) -> DiffResult {
        var lines: [DiffLine] = []
        for (idx, line) in orig.enumerated() {
            lines.append(DiffLine(kind: .deleted, oldLineNumber: idx + 1, newLineNumber: nil, text: line))
        }
        for (idx, line) in mod.enumerated() {
            lines.append(DiffLine(kind: .added, oldLineNumber: nil, newLineNumber: idx + 1, text: line))
        }
        return DiffResult(lines: lines)
    }
}
