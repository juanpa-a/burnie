import BurnieInterface
import Foundation

/// An `AppLifecycle` that counts quits instead of quitting.
@MainActor
public final class RecordingAppLifecycle: AppLifecycle {
    public private(set) var quits = 0

    public init() {}

    public func quit() {
        quits += 1
    }
}
