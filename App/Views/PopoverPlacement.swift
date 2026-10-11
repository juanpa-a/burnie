import AppKit

/// Keeps the popover window centered under the menu bar icon, without leaving the screen.
/// macOS aligns it to the icon's left edge, and realigns it every time the content changes height.
@MainActor
final class PopoverPlacement {
    private weak var window: NSWindow?
    private var observers: [NSObjectProtocol] = []

    func keepCentered(_ window: NSWindow) {
        if window !== self.window {
            follow(window)
        }
        center()
    }

    private func follow(_ window: NSWindow) {
        self.window = window
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = [NSWindow.didResizeNotification, NSWindow.didMoveNotification].map { name in
            NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.center() }
            }
        }
    }

    private func center() {
        guard let window, let statusItem = NSApp.windows.first(where: Self.isStatusItemWindow)?.frame, let screen = window.screen else { return }
        let visible = screen.visibleFrame
        let x = min(max(statusItem.midX - window.frame.width / 2, visible.minX), visible.maxX - window.frame.width)
        // Moving triggers didMove: if it's already in place it isn't touched, so there's no loop.
        guard abs(window.frame.minX - x) >= 1 else { return }
        window.setFrameOrigin(NSPoint(x: x, y: window.frame.minY))
    }

    /// AppKit draws each menu bar icon in its own `NSStatusBarWindow`.
    private static func isStatusItemWindow(_ window: NSWindow) -> Bool {
        window.className == "NSStatusBarWindow"
    }
}
