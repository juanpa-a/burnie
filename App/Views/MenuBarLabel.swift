import AppKit
import BurnieComponents
import BurnieDomain
import BurnieInterface
import SwiftUI

/// The `MenuBarExtra` label. The label doesn't draw shapes reliably, so `MenuBarIcon` goes through `ImageRenderer` into
/// a template `NSImage`. SwiftUI only reruns `body` when `ring` changes, and `ring` moves in whole percents.
struct MenuBarLabel: View {
    let ring: RingState
    /// For VoiceOver's name of the provider the ring follows (B-54).
    let providers: [ProviderPanel]
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Image(nsImage: templateImage)
            .accessibilityLabel(RingAccessibilityLabel.text(for: ring, providers: providers))
    }

    private var templateImage: NSImage {
        let renderer = ImageRenderer(content: MenuBarIcon(ring: ring))
        renderer.scale = displayScale
        let image = renderer.nsImage ?? NSImage()
        image.isTemplate = true
        return image
    }
}
