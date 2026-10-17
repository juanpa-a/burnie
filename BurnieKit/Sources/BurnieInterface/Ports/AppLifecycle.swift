import Foundation

/// The app's own lifecycle.
@MainActor
public protocol AppLifecycle {
    func quit()
}
