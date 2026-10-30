import BurnieInterface
import Foundation

/// An `Updater` that reports the version the test says.
@MainActor
public final class FakeUpdater: Updater {
    private var onUpdate: (@Sendable (String?) -> Void)?
    private var onResult: (@Sendable (UpdateCheckResult) -> Void)?
    private var sessionInProgress = false
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
        guard !sessionInProgress else {
            onResult(.failed)
            return
        }
        self.onResult = onResult
    }

    /// What a scheduled check reports.
    public func report(_ version: String?) {
        sessionInProgress = version != nil
        onUpdate?(version)
    }

    /// What a user-initiated check comes back with (B-82).
    public func resolve(_ result: UpdateCheckResult) {
        if case .found(let version) = result {
            report(version)
        }
        onResult?(result)
        onResult = nil
    }
}
