import SwiftUI

/// A setting on the providers screen: a title, a one-line subtitle and a switch. Each caller sets its own padding.
/// Under `.disabled(true)` it dims and reads off whatever `isOn` holds, so the saved value survives.
struct SwitchRow: View {
    let title: String
    let subtitle: Text
    @Binding var isOn: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Tokens.Typography.title)
                    .foregroundStyle(Tokens.Palette.fg)
                    .opacity(isEnabled ? 1 : Tokens.offOpacity)
                subtitle
                    .font(Tokens.Typography.caption)
                    .foregroundStyle(Tokens.Palette.fg2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Toggle(title, isOn: isEnabled ? $isOn : .constant(false))
                .toggleStyle(BurnieSwitchStyle(onColor: Tokens.Palette.switchOn))
                .labelsHidden()
                .opacity(isEnabled ? 1 : Tokens.disabledSwitchOpacity)
        }
    }
}
