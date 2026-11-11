import SwiftUI
import Combine

/// View model for the floating toolbar
final class FloatingBarViewModel: ObservableObject {
    @Published var isVisible: Bool = false
    @Published var showFeedback: Bool = false
    @Published var feedbackMessage: String = "Copied"

    let actions: [ActionType]
    let onAction: (ActionType) -> Void
    let onDismiss: () -> Void

    private(set) var buttonViewModels: [ActionButtonViewModel] = []

    init(actions: [ActionType], onAction: @escaping (ActionType) -> Void, onDismiss: @escaping () -> Void) {
        self.actions = actions
        self.onAction = onAction
        self.onDismiss = onDismiss

        self.buttonViewModels = actions.map { action in
            ActionButtonViewModel(action: action) { [weak self] in
                guard let self = self else { return }
                if action == .copy {
                    self.triggerFeedback(message: "Copied")
                } else if action == .formatJSON {
                    self.triggerFeedback(message: "JSON Formatted & Copied")
                }
                self.onAction(action)
            }
        }
    }

    func animateIn() {
        withAnimation(.easeOut(duration: DesignTokens.Animation.appearDuration)) {
            isVisible = true
        }
    }

    func animateOut(completion: @escaping () -> Void) {
        withAnimation(.easeIn(duration: DesignTokens.Animation.disappearDuration)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignTokens.Animation.disappearDuration) {
            completion()
        }
    }

    func triggerFeedback(message: String = "Copied") {
        feedbackMessage = message
        withAnimation(.easeOut(duration: 0.15)) {
            showFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
            withAnimation(.easeIn(duration: DesignTokens.Animation.disappearDuration)) {
                self?.showFeedback = false
            }
        }
    }
}

/// The main floating glass capsule toolbar
struct FloatingBarView: View {
    @ObservedObject var viewModel: FloatingBarViewModel

    var body: some View {
        ZStack {
            // Main toolbar items
            HStack(spacing: DesignTokens.Toolbar.buttonSpacing) {
                ForEach(Array(viewModel.buttonViewModels.enumerated()), id: \.element.action.id) { index, buttonVM in
                    // Separator before the 'more' button
                    if buttonVM.action == .more && index > 0 {
                        Rectangle()
                            .fill(DesignTokens.Colors.separator)
                            .frame(width: 0.5, height: 18)
                            .padding(.horizontal, 1)
                    }

                    ActionButton(viewModel: buttonVM)
                }
            }
            .padding(.horizontal, DesignTokens.Toolbar.horizontalPadding)
            .padding(.vertical, DesignTokens.Toolbar.verticalPadding)
            .glassCapsuleStyle()

            // Visual checkmark feedback on copy or formatting
            if viewModel.showFeedback {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                    Text(viewModel.feedbackMessage)
                        .font(DesignTokens.Typography.toolbarLabel)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.vertical, DesignTokens.Spacing.md)
                .glassCapsuleStyle()
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .opacity(viewModel.isVisible ? 1 : 0)
        .scaleEffect(viewModel.isVisible ? 1 : DesignTokens.Animation.appearScale)
        .offset(y: viewModel.isVisible ? 0 : 4)
        .onAppear {
            viewModel.animateIn()
        }
    }
}
