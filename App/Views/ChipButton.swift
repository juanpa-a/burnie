import SwiftUI

/// A small button on a chip background, for an action inside the popover's content ("Choose providers").
struct ChipButton: View {
    let title: String
    /// Shows a spinner and ignores taps while its action runs.
    var isBusy = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isBusy {
                    ProgressView()
                        .controlSize(.mini)
                }
                Text(title)
                    .font(Tokens.Typography.meterLabel)
                    .foregroundStyle(Tokens.Palette.fg)
            }
            .padding(.horizontal, 10)
            .frame(height: Tokens.Metrics.chipButtonHeight)
            .background(RoundedRectangle(cornerRadius: Tokens.Metrics.iconButtonRadius).fill(Tokens.Palette.chip))
        }
        .buttonStyle(HoverHighlightStyle(cornerRadius: Tokens.Metrics.iconButtonRadius))
        .disabled(isBusy)
    }
}
