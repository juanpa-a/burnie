import Foundation

extension Meter {
    /// The pace: how far through its period `now` is, which is where the fill would be at an even rate.
    /// nil without a period, with a zero-length one, or once `now` falls outside it, like a reset that already happened.
    public func elapsedFraction(at now: Date) -> Fraction? {
        guard let period, period.duration > 0, period.contains(now) else { return nil }
        return Fraction(now.timeIntervalSince(period.start) / period.duration)
    }

    /// The part of the fill past the pace, which draws in the over-pace color; zero without a pace (B-5).
    public func overPace(at now: Date) -> Fraction {
        guard let pace = elapsedFraction(at: now) else { return .zero }
        return Fraction(fill.value - pace.value)
    }
}
