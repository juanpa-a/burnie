import BurnieInterface
import Foundation

/// An `Updater` that reports the version the test says.
@MainActor
public final class FakeUpdater: Updater {
    private var onUpdate: (@Sendable (String?) -> Void)?
    private var onResult: (@Sendable (UpdateCheckResult) -> Void)?
    public private(set) var installs = 0
    public private(set) var checks = 0

    public init() {}

    public func start(onUpdate: @escaping @Sendable (_ version: String?) -> Void) {
        self.onUpdate = onUpdate
    }

    public func install() {
        installs += 1
    }

    public func checkForUpdates(onResult: @escaping @Sendable (UpdateCheckResult) -> Void) {
        checks += 1
        self.onResult = onResult
    }

    /// What a scheduled check reports.
    public func report(_ version: String?) {
        onUpdate?(version)
    }

    /// What a user-initiated check comes back with (B-76).
    public func resolve(_ result: UpdateCheckResult) {
        onResult?(result)
        onResult = nil
    }
}
