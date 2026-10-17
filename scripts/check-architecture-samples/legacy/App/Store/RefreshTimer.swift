// expect: G-6
import BurnieCore
import Foundation
import Sparkle

/// Decides when to refresh by reading the system clock.
@MainActor
final class RefreshTimer {
    private var lastRun: Date?

    func shouldRun() -> Bool {
        guard let lastRun else { return true }
        return lastRun.addingTimeInterval(60) < Date.now
    }
}
