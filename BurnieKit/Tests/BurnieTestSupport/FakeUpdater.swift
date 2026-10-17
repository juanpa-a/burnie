import BurnieInterface
import Foundation

/// An `Updater` that reports the version the test says.
@MainActor
public final class FakeUpdater: Updater {
    private var onUpdate: (@Sendable (String?) -> Void)?
    public private(set) var installs = 0

    public init() {}

    public func start(onUpdate: @escaping @Sendable (_ version: String?) -> Void) {
        self.onUpdate = onUpdate
    }

    public func install() {
        installs += 1
    }

    /// What a scheduled check reports.
    public func report(_ version: String?) {
        onUpdate?(version)
    }
}
