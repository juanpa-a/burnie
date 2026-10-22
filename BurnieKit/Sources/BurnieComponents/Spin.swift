import SwiftUI

/// One stretch of the Refresh arrow spinning, timed from when it started: the angle depends only on the clock,
/// so no turn schedules the next one and nothing keeps running when the button leaves the screen mid-turn.
struct Spin {
    private static let turnDuration: TimeInterval = 0.7

    private let start: Date
    /// When the arrow comes to rest; `nil` while Refresh is still in progress.
    private(set) var end: Date?

    init(startingAt start: Date) {
        self.start = start
    }

    func angle(at date: Date) -> Angle {
        let turns = turnsElapsed(at: min(date, end ?? date))
        return .degrees(turns.truncatingRemainder(dividingBy: 1) * 360)
    }

    /// Rests at the end of the turn it's on, and never before one full turn, so the arrow doesn't snap back.
    mutating func stop(at date: Date) {
        let turns = max(turnsElapsed(at: date).rounded(.up), 1)
        end = start.addingTimeInterval(turns * Self.turnDuration)
    }

    mutating func resume() {
        end = nil
    }

    private func turnsElapsed(at date: Date) -> Double {
        date.timeIntervalSince(start) / Self.turnDuration
    }
}
