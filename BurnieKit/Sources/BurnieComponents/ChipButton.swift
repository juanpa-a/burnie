import BurnieInterface
import SwiftUI

/// A small button on a chip background, for an action inside the popover's content ("Choose providers").
public struct ChipButton: View {
    let title: String
    /// Shows a spinner and ignores taps while its action runs.
    let isBusy: Bool
    let action: () -> Void

    public init(title: String, isBusy: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isBusy = isBusy
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.iconAndText) {
                if isBusy {
                    ProgressView()
                        .controlSize(.mini)
                }
                Text(title)
                    .font(DesignTokens.Typography.meterLabel)
                    .foregroundStyle(DesignTokens.Palette.fg)
            }
            .padding(.horizontal, DesignTokens.Insets.control)
            .frame(height: DesignTokens.Metrics.chipButtonHeight)
            .background(RoundedRectangle(cornerRadius: DesignTokens.Metrics.iconButtonRadius).fill(DesignTokens.Palette.chip))
        }
        .buttonStyle(HoverHighlightStyle(cornerRadius: DesignTokens.Metrics.iconButtonRadius))
        .disabled(isBusy)
    }
}

#if DEBUG
#Preview {
    PreviewFrame {
        ChipButton(title: Copy.chooseProviders) {}
        ChipButton(title: Copy.renewSignIn, isBusy: true) {}
    }
}
#endif
