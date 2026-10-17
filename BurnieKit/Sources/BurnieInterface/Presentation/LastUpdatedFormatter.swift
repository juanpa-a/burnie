import Foundation

/// The line under "Usage" in the header: how old the most recent data is.
public struct LastUpdatedFormatter: Sendable {
    public init() {}

    public func string(lastUpdated: Date?, now: Date) -> String {
        guard let lastUpdated else { return "Updating…" }
        let minutes = Int(now.timeIntervalSince(lastUpdated) / 60)
        if minutes < 1 { return "Updated just now" }
        if minutes < 60 { return "Updated \(minutes) min ago" }
        return "Updated \(minutes / 60) h ago"
    }
}
