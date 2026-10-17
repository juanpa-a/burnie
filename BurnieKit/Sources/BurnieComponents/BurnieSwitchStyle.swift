import SwiftUI

/// The design's 38×22 switch: `onColor` when on, `toggleOff` when off.
public struct BurnieSwitchStyle: ToggleStyle {
    let onColor: Color

    public init(onColor: Color) {
        self.onColor = onColor
    }

    public func makeBody(configuration: Configuration) -> some View {
        let size = DesignTokens.Metrics.switchSize
        Button {
            configuration.isOn.toggle()
        } label: {
            Capsule()
                .fill(configuration.isOn ? onColor : DesignTokens.Palette.toggleOff)
                .frame(width: size.width, height: size.height)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(DesignTokens.Palette.switchKnob)
                        .frame(width: DesignTokens.Metrics.switchKnob, height: DesignTokens.Metrics.switchKnob)
                        .shadow(
                            color: DesignTokens.Palette.switchKnobShadow,
                            radius: DesignTokens.Metrics.switchKnobShadowRadius,
                            y: DesignTokens.Metrics.switchKnobShadowOffset
                        )
                        .padding(DesignTokens.Metrics.switchKnobInset)
                }
                .animation(DesignTokens.Motion.switchToggle, value: configuration.isOn)
        }
        .buttonStyle(.plain)
        // VoiceOver announces it as a switch, like the system control.
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
        }
    }
}

#Preview {
    PreviewFrame {
        Toggle(PreviewValues.switchTitle, isOn: .constant(true))
            .toggleStyle(BurnieSwitchStyle(onColor: DesignTokens.Palette.switchOn))
            .labelsHidden()
    }
}
