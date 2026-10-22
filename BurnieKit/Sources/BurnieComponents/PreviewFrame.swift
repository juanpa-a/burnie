#if DEBUG
import SwiftUI

/// Shows a popover view in light and dark side by side, at the real width and background.
public struct PreviewFrame<Content: View>: View {
    @ViewBuilder let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.previews) {
            ForEach([ColorScheme.light, .dark], id: \.self) { scheme in
                content
                    .frame(width: DesignTokens.Metrics.popoverWidth)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(DesignTokens.Palette.pop)
                    .environment(\.colorScheme, scheme)
            }
        }
        .padding(DesignTokens.Insets.preview)
        .background(DesignTokens.Palette.previewBackdrop)
    }
}
#endif
