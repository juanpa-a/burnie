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
}

extension SparkleUpdater: SPUUpdaterDelegate {
    nonisolated public func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        let version = item.displayVersionString
        MainActor.assumeIsolated { onUpdate?(version) }
    }

    /// Also what a skipped version reports on the next check, so the dot goes away.
    nonisolated public func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        MainActor.assumeIsolated { onUpdate?(nil) }
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
