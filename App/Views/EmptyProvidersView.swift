import SwiftUI

/// What takes the place of the sections when every provider is off.
struct EmptyProvidersView: View {
    let onChooseProviders: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("No providers on")
                .font(Tokens.Typography.title)
                .foregroundStyle(Tokens.Palette.fg)
            ChipButton(title: "Choose providers", action: onChooseProviders)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}
