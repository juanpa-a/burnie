import AppKit
import BurnieInterface

/// `AppLifecycle` over `NSApplication`.
@MainActor
public struct NSAppLifecycle: AppLifecycle {
    public init() {}

    public func quit() {
        NSApp.terminate(nil)
    }
}
