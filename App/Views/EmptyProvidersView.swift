import SwiftUI

/// What takes the place of the sections when every provider is off.
struct EmptyProvidersView: View {
    let onChooseProviders: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("No providers on")
                .font(Tokens.Typography.title)
                .foregroundStyle(Tokens.Palette.fg)
            Button(action: onChooseProviders) {
                Text("Choose providers")
                    .font(Tokens.Typography.meterLabel)
                    .foregroundStyle(Tokens.Palette.fg)
                    .padding(.horizontal, 10)
                    .frame(height: 24)
                    .background(RoundedRectangle(cornerRadius: Tokens.Metrics.iconButtonRadius).fill(Tokens.Palette.chip))
            }
            .buttonStyle(HoverHighlightStyle(cornerRadius: Tokens.Metrics.iconButtonRadius))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}
