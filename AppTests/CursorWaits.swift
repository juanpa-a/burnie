import Foundation

/// Cursor's limits wait 10 min ± 30 s and its activity 30 min, so their timers never look like Claude's 5 min ± 30 s
/// or each other.
enum CursorWaits {
    static let limits: ClosedRange<TimeInterval> = 570...630
    static let activity: TimeInterval = 1_800
}
