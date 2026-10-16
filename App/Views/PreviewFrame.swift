#if DEBUG
import SwiftUI

/// Shows a popover view in light and dark side by side, at the real width and background.
struct PreviewFrame<Content: View>: View {
    /// The version the updater offers, for the update dot and row.
    var availableUpdate: String?
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            ForEach([ColorScheme.light, .dark], id: \.self) { scheme in
                content
                    .frame(width: Tokens.Metrics.popoverWidth)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(Tokens.Palette.pop)
                    .environment(\.colorScheme, scheme)
            }
        }
        .padding(24)
        .background(Color.gray.opacity(0.3))
        .environment(LaunchAtLogin())
        .environment(AppUpdater.preview(availableVersion: availableUpdate))
    }
}
#endif
