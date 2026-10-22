import SwiftUI

/// A setting on the providers screen: a title, a one-line subtitle and a switch. Each caller sets its own padding.
/// Under `.disabled(true)` it dims and reads off whatever `isOn` holds, so the saved value survives (B-74).
public struct SwitchRow: View {
    let title: String
    let subtitle: Text
    @Binding var isOn: Bool
    @Environment(\.isEnabled) private var isEnabled

    public init(title: String, subtitle: Text, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        _isOn = isOn
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.rowItems) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.textLines) {
                Text(title)
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Palette.fg)
                    .opacity(isEnabled ? DesignTokens.Opacity.opaque : DesignTokens.Opacity.off)
                subtitle
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Palette.fg2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Toggle(title, isOn: isEnabled ? $isOn : .constant(false))
                .toggleStyle(BurnieSwitchStyle(onColor: DesignTokens.Palette.switchOn))
                .labelsHidden()
                .opacity(isEnabled ? DesignTokens.Opacity.opaque : DesignTokens.Opacity.disabledSwitch)
        }
    }
}

#if DEBUG
#Preview {
    PreviewFrame {
        SwitchRow(title: PreviewValues.switchTitle, subtitle: Text(PreviewValues.switchSubtitle), isOn: .constant(true))
        SwitchRow(title: PreviewValues.switchTitle, subtitle: Text(PreviewValues.switchSubtitle), isOn: .constant(true))
            .disabled(true)
    }
}
#endif
