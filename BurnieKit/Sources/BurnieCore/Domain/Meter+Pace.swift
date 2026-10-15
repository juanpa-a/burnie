import Foundation

extension Meter {
    /// How far through its period `now` is, from 0 to 1: where the bar would be at an even pace.
    /// nil without a period, or once `now` falls outside it, like a reset that already happened.
    public func elapsedFraction(at now: Date) -> Double? {
        guard let period, period.duration > 0, period.contains(now) else { return nil }
        return now.timeIntervalSince(period.start) / period.duration
    }
}
