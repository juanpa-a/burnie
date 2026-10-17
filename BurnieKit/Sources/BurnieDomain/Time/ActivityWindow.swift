import Foundation

/// The days each activity refresh recomputes: today and the 7 before (B-41).
/// Older days stay frozen in the history, because providers forget them.
public enum ActivityWindow {
    public static let dayCount = 8

    public static func days(endingAt today: LocalDay) -> ClosedRange<LocalDay> {
        today.advanced(by: 1 - dayCount)...today
    }
}
