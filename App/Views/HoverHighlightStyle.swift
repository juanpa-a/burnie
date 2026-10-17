import SwiftUI

/// Rounded `hover` background while the pointer is over it, for icon buttons and footer items.
struct HoverHighlightStyle: ButtonStyle {
    let cornerRadius: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        HoverHighlight(cornerRadius: cornerRadius) { configuration.label }
    }

    private struct HoverHighlight<Label: View>: View {
        let cornerRadius: CGFloat
        @ViewBuilder let label: Label
        @State private var isHovering = false
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            label
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(isHovering && isEnabled ? Tokens.Palette.hover : .clear)
                )
                .onHover { isHovering = $0 }
        }
    }
}
