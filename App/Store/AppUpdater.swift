import AppKit
import Sparkle

/// Burnie's own updates, with Sparkle. It checks the GitHub releases feed once a day, quietly:
/// a new version shows as a dot on the gear and an Update row instead of Sparkle's alert.
/// Update opens Sparkle's window, which downloads, installs and relaunches.
@MainActor @Observable
final class AppUpdater: NSObject {
    /// The newer version on the feed ("0.3.0"), or nil while Burnie is up to date.
    private(set) var availableVersion: String?

    @ObservationIgnored private var controller: SPUStandardUpdaterController?

    private init(availableVersion: String? = nil) {
        self.availableVersion = availableVersion
    }

    static func live() -> AppUpdater {
        let updater = AppUpdater()
        updater.controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: updater, userDriverDelegate: updater)
        return updater
    }

    #if DEBUG
    /// Never starts Sparkle, so previews touch neither network nor disk.
    static func preview(availableVersion: String? = nil) -> AppUpdater {
        AppUpdater(availableVersion: availableVersion)
    }
    #endif

    func installUpdate() {
        // A menu bar app isn't active, and Sparkle's window would open behind the frontmost app.
        NSApp.activate()
        controller?.checkForUpdates(nil)
    }
}

extension AppUpdater: SPUUpdaterDelegate {
    nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        let version = item.displayVersionString
        MainActor.assumeIsolated { availableVersion = version }
    }

    /// Also what a skipped version reports on the next check, so the dot goes away.
    nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        MainActor.assumeIsolated { availableVersion = nil }
    }
}

extension AppUpdater: SPUStandardUserDriverDelegate {
    nonisolated var supportsGentleScheduledUpdateReminders: Bool { true }

    /// Scheduled checks never open Sparkle's alert: the dot and the Update row take its place.
    nonisolated func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool {
        false
    }
}
