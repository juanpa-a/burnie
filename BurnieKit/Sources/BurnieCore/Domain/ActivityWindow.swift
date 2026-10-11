import Foundation

/// The days each refresh recomputes from the activity source: today and the 7 before.
/// Older days stay frozen in the history because the sources forget them.
public enum ActivityWindow {
    public static let dayCount = 8

    public static func days(endingAt today: LocalDay) -> ClosedRange<LocalDay> {
        today.advanced(by: 1 - dayCount)...today
    }
}
