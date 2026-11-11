import SwiftUI

/// Observable state holder for DiffView (avoids Swift macro requirements)
final class DiffViewState: ObservableObject {
    @Published var isWordWrapEnabled: Bool = false
}

/// Elegant, Apple-native code diff preview view
public struct DiffView: View {
    public let originalCode: String
    public let modifiedCode: String
    public let language: CodeLanguage
    public let onReplace: () -> Void
    public let onCopy: () -> Void

    @ObservedObject private var state: DiffViewState = DiffViewState()
    private let diffResult: DiffResult

    public init(
        originalCode: String,
        modifiedCode: String,
        language: CodeLanguage = .generic,
        onReplace: @escaping () -> Void,
        onCopy: @escaping () -> Void
    ) {
        self.originalCode = originalCode
        self.modifiedCode = modifiedCode
        self.language = language
        self.onReplace = onReplace
        self.onCopy = onCopy
        self.diffResult = DiffEngine.computeDiff(original: originalCode, modified: modifiedCode)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            diffHeaderBar

            Divider()
                .opacity(0.12)

            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(diffResult.lines) { line in
                        diffLineRow(line)
                    }
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.primary.opacity(0.02))

            Divider()
                .opacity(0.12)

            diffFooterBar
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 0.5)
        )
    }

    // MARK: - Header Bar

    private var diffHeaderBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

                Text("CODE CHANGES PREVIEW")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Statistics badge
            HStack(spacing: 6) {
                Text("+\(diffResult.addedCount)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.green)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())

                Text("-\(diffResult.deletedCount)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.red.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Word wrap toggle
            Button(action: {
                state.isWordWrapEnabled.toggle()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: state.isWordWrapEnabled ? "text.wrap" : "arrow.left.and.right")
                        .font(.system(size: 9))
                    Text(state.isWordWrapEnabled ? "Wrap" : "Scroll")
                        .font(.system(size: 10))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.04))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.03))
    }

    // MARK: - Diff Line Row

    private func diffLineRow(_ line: DiffLine) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Old line number
            Text(line.oldLineNumber.map { "\($0)" } ?? "")
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(.secondary.opacity(0.45))
                .frame(width: 28, alignment: .trailing)
                .padding(.trailing, 4)

            // New line number
            Text(line.newLineNumber.map { "\($0)" } ?? "")
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(.secondary.opacity(0.45))
                .frame(width: 28, alignment: .trailing)
                .padding(.trailing, 6)

            // Prefix (+, -, or space)
            Text(linePrefix(for: line.kind))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(linePrefixColor(for: line.kind))
                .frame(width: 14, alignment: .center)

            // Code text
            Text(line.text.isEmpty ? " " : line.text)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(lineTextColor(for: line.kind))
                .lineLimit(state.isWordWrapEnabled ? nil : 1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 1)
        .background(lineBackgroundColor(for: line.kind))
    }

    // MARK: - Footer Bar

    private var diffFooterBar: some View {
        HStack(spacing: 8) {
            Button(action: onCopy) {
                Label("Copy New Code", systemImage: "doc.on.doc")
                    .font(.system(size: 11))
            }
            .buttonStyle(.bordered)

            Spacer()

            Button(action: onReplace) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                    Text("Replace Selection (替换选中代码)")
                        .font(.system(size: 11, weight: .semibold))
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.02))
    }

    // MARK: - Color & Style Helpers

    private func linePrefix(for kind: DiffLine.Kind) -> String {
        switch kind {
        case .added: return "+"
        case .deleted: return "-"
        case .unchanged: return " "
        }
    }

    private func linePrefixColor(for kind: DiffLine.Kind) -> Color {
        switch kind {
        case .added: return .green
        case .deleted: return .red
        case .unchanged: return .secondary.opacity(0.3)
        }
    }

    private func lineTextColor(for kind: DiffLine.Kind) -> Color {
        switch kind {
        case .added: return .primary
        case .deleted: return .secondary
        case .unchanged: return .primary.opacity(0.85)
        }
    }

    private func lineBackgroundColor(for kind: DiffLine.Kind) -> Color {
        switch kind {
        case .added:
            return Color.green.opacity(0.12)
        case .deleted:
            return Color.red.opacity(0.12)
        case .unchanged:
            return Color.clear
        }
    }
}
