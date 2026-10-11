import SwiftUI

/// The design's 38×22 switch: `onColor` when on, `toggleOff` when off.
struct BurnieSwitchStyle: ToggleStyle {
    let onColor: Color

    func makeBody(configuration: Configuration) -> some View {
        let size = Tokens.Metrics.switchSize
        Button {
            configuration.isOn.toggle()
        } label: {
            Capsule()
                .fill(configuration.isOn ? onColor : Tokens.Palette.toggleOff)
                .frame(width: size.width, height: size.height)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: Tokens.Metrics.switchKnob, height: Tokens.Metrics.switchKnob)
                        .shadow(color: .black.opacity(0.3), radius: 1.5, y: 1)
                        .padding(2)
                }
                .animation(.easeInOut(duration: 0.15), value: configuration.isOn)
        }
        .buttonStyle(.plain)
        // VoiceOver announces it as a switch, like the system control.
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
        }
    }
}
