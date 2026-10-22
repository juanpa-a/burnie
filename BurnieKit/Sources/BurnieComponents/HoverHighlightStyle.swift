import SwiftUI

/// Rounded `hover` background while the pointer is over it, for icon buttons and footer items.
public struct HoverHighlightStyle: ButtonStyle {
    let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
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
                        .fill(isHovering && isEnabled ? DesignTokens.Palette.hover : .clear)
                )
                .onHover { isHovering = $0 }
        }
    }
}

#if DEBUG
#Preview {
    PreviewFrame {
        Button(PreviewValues.footerTitle) {}
            .buttonStyle(HoverHighlightStyle(cornerRadius: DesignTokens.Metrics.footerItemRadius))
    }
}
#endif
