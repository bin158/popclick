import Foundation

/// Defines a PopClick plugin that extends toolbar actions
struct Plugin: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var icon: String
    var description: String
    var shortcut: String?
    var category: Category
    var actionType: ActionKind
    var payload: String
    var isEnabled: Bool

    enum Category: String, Codable, CaseIterable {
        case web = "Web"
        case ai = "AI"
        case utilities = "Utilities"
        case developer = "Developer"
    }

    enum ActionKind: String, Codable {
        case urlTemplate
        case aiPrompt
        case shellScript
        case markdownTransform
    }
}
