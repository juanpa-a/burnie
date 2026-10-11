import Foundation

public struct DailyPoint: Codable, Sendable, Equatable {
    public var day: LocalDay
    /// That day's tokens.
    public var value: Int

    public init(day: LocalDay, value: Int) {
        self.day = day
        self.value = value
    }
}
