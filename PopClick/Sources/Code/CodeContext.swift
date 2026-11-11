import Foundation

/// Manages multi-level code context (Selection, Surroundings, Full File) and target application info
public struct CodeContext: Codable {

    public enum ContextMode: String, CaseIterable, Identifiable, Codable {
        case selectionOnly = "Selection"
        case selectionWithSurroundings = "Selection + Surrounding"
        case fullFile = "Full File"

        public var id: String { rawValue }

        public var shortLabel: String {
            switch self {
            case .selectionOnly: return "Selection"
            case .selectionWithSurroundings: return "+ Context"
            case .fullFile: return "Full File"
            }
        }
    }

    public let selectedCode: String
    public let surroundingBefore: String?
    public let surroundingAfter: String?
    public let fullFileContent: String?
    public let appName: String?
    public let appBundleId: String?
    public let filePath: String?
    public let fileExtension: String?
    public var detectedLanguage: CodeLanguage
    public var contextMode: ContextMode

    public var isLikelyCode: Bool {
        return detectedLanguage != .generic || (fileExtension != nil && !fileExtension!.isEmpty) || (appName != nil && !appName!.isEmpty)
    }

    public init(
        selectedCode: String,
        surroundingBefore: String? = nil,
        surroundingAfter: String? = nil,
        fullFileContent: String? = nil,
        appName: String? = nil,
        appBundleId: String? = nil,
        filePath: String? = nil,
        fileExtension: String? = nil,
        detectedLanguage: CodeLanguage = .generic,
        contextMode: ContextMode = .selectionOnly
    ) {
        self.selectedCode = selectedCode
        self.surroundingBefore = surroundingBefore
        self.surroundingAfter = surroundingAfter
        self.fullFileContent = fullFileContent
        self.appName = appName
        self.appBundleId = appBundleId
        self.filePath = filePath
        self.fileExtension = fileExtension
        self.detectedLanguage = detectedLanguage
        self.contextMode = contextMode
    }

    /// Formats the prompt payload sent to AI according to the active ContextMode
    public func buildPromptContext() -> String {
        let langName = detectedLanguage.displayName
        let commentPrefix = detectedLanguage.lineCommentPrefix

        switch contextMode {
        case .selectionOnly:
            return selectedCode

        case .selectionWithSurroundings:
            var sections: [String] = []
            if let before = surroundingBefore, !before.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sections.append("\(commentPrefix) --- Context Before ---")
                sections.append(before)
            }

            sections.append("\(commentPrefix) >>> SELECTED CODE (TARGET FOR ACTION) <<<")
            sections.append(selectedCode)
            sections.append("\(commentPrefix) >>> END OF SELECTED CODE <<<")

            if let after = surroundingAfter, !after.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sections.append("\(commentPrefix) --- Context After ---")
                sections.append(after)
            }

            return sections.joined(separator: "\n")

        case .fullFile:
            if let full = fullFileContent, !full.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "\(commentPrefix) Language: \(langName)\n\(commentPrefix) Target Selected Code Snippet:\n\(selectedCode)\n\n\(commentPrefix) --- Full File Context ---\n\(full)"
            }
            return selectedCode
        }
    }
}
