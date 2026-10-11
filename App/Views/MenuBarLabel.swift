import AppKit
import BurnieCore
import SwiftUI

/// The `MenuBarExtra` label. The label doesn't draw shapes reliably, so `MenuBarIcon` goes through `ImageRenderer`
/// into a template `NSImage`. SwiftUI only reruns `body` when `ring` changes, and `ring` moves in whole percents.
struct MenuBarLabel: View {
    let ring: RingState
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Image(nsImage: templateImage)
            .accessibilityLabel(ring.accessibilityLabel)
    }

    private var templateImage: NSImage {
        let renderer = ImageRenderer(content: MenuBarIcon(ring: ring))
        renderer.scale = displayScale
        let image = renderer.nsImage ?? NSImage()
        image.isTemplate = true
        return image
    }
}
