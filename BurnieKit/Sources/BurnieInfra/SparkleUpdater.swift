import AppKit
import BurnieInterface
import Sparkle

/// `Updater` over Sparkle. It checks the release feed once a day, quietly: a new version is reported, to show as a dot
/// on the gear and an Update row, instead of Sparkle's alert. Installing opens Sparkle's window, which downloads,
/// installs and relaunches (B-57).
@MainActor
public final class SparkleUpdater: NSObject, Updater {
    private var controller: SPUStandardUpdaterController?
    private var onUpdate: (@Sendable (String?) -> Void)?
    private var onResult: (@Sendable (UpdateCheckResult) -> Void)?

    override public init() {}

    public func start(onUpdate: @escaping @Sendable (_ version: String?) -> Void) {
        self.onUpdate = onUpdate
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: self)
    }

    public func install() {
        // A menu bar app isn't active, and Sparkle's window would open behind the frontmost app.
        NSApp.activate()
        controller?.checkForUpdates(nil)
    }

    public func checkForUpdates(onResult: @escaping @Sendable (UpdateCheckResult) -> Void) {
        guard let updater = controller?.updater, !updater.sessionInProgress else {
            onResult(.failed)
            return
        }
        self.onResult = onResult
        // A background check opens no UI; the delegates below report how it went (B-82).
        updater.checkForUpdatesInBackground()
    }

    /// A scheduled check can finish while the user's is in flight; either delegate answer reflects the latest feed
    /// state, so reporting it to the waiting check is correct. With no check waiting (`onResult == nil`), reporting is
    /// a no-op and scheduled checks stay quiet (B-57).
    private func report(_ result: UpdateCheckResult) {
        onResult?(result)
        onResult = nil
    }
}

extension SparkleUpdater: SPUUpdaterDelegate {
    nonisolated public func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        let version = item.displayVersionString
        MainActor.assumeIsolated {
            onUpdate?(version)
            report(.found(version))
        }
    }

    /// Also what a skipped version reports on the next check, so the dot goes away.
    nonisolated public func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        MainActor.assumeIsolated {
            onUpdate?(nil)
            report(.upToDate)
        }
    }

    nonisolated public func updater(_ updater: SPUUpdater, didAbortWithError error: any Error) {
        MainActor.assumeIsolated { report(.failed) }
    }
}

extension SparkleUpdater: SPUStandardUserDriverDelegate {
    nonisolated public var supportsGentleScheduledUpdateReminders: Bool { true }

    /// Scheduled checks never open Sparkle's alert: the dot and the Update row take its place.
    nonisolated public func standardUserDriverShouldHandleShowingScheduledUpdate(
        _ update: SUAppcastItem,
        andInImmediateFocus immediateFocus: Bool
    ) -> Bool {
        false
    }
}
