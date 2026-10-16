import SwiftUI

/// The top of the providers screen while a new Burnie is available. Update hands over to Sparkle's window.
struct UpdateRow: View {
    let version: String
    let onUpdate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Update available")
                    .font(Tokens.Typography.title)
                    .foregroundStyle(Tokens.Palette.fg)
                Text("Burnie \(version)")
                    .font(Tokens.Typography.caption)
                    .foregroundStyle(Tokens.Palette.fg2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            ChipButton(title: "Update", action: onUpdate)
        }
        .padding(Tokens.Metrics.settingRowInsets)
    }
}
