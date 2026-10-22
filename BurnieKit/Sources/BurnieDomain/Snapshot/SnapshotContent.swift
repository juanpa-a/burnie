import Foundation

/// What a snapshot is made of: a stamped limits part with today's usage if known, or a stamped today's usage alone.
/// A snapshot with neither can't be built.
public enum SnapshotContent: Hashable, Sendable {
    /// `today` is nil when the activity failed or never loaded.
    case limits(view: Stamped<LimitsPart>, today: TodayUsage?)
    /// The limits failed or never loaded.
    case activityOnly(Stamped<TodayUsage>)
}
