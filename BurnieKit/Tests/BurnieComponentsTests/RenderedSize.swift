import SwiftUI

/// What a component draws to, in a smoke test: the size of its rendered image, nil when nothing rendered.
@MainActor
enum RenderedSize {
    static func of(_ view: some View, width: CGFloat = 340) -> CGSize? {
        let renderer = ImageRenderer(content: view.frame(width: width).fixedSize(horizontal: false, vertical: true))
        guard let image = renderer.cgImage else { return nil }
        return CGSize(width: image.width, height: image.height)
    }

    /// Whether `view` rendered at a non-zero size, in light and in dark appearance.
    static func isDrawn(_ view: some View, width: CGFloat = 340) -> Bool {
        [ColorScheme.light, .dark].allSatisfy { scheme in
            of(view.environment(\.colorScheme, scheme), width: width).map { $0.width > 0 && $0.height > 0 } ?? false
        }
    }
}
