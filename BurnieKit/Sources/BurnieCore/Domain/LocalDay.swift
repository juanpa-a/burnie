import Foundation

/// A calendar day in the system time zone, like "2026-10-10".
///
/// Encoded as a plain string and usable as a JSON dictionary key.
/// Day arithmetic happens in UTC so daylight saving changes don't shift dates.
public struct LocalDay: Hashable, Sendable {
    public let iso: String

    public init(_ date: Date, in calendar: Calendar) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year!, month: parts.month!, day: parts.day!)
    }

    public init(_ date: Date, in timeZone: TimeZone) {
        self.init(date, in: .gregorian(in: timeZone))
    }

    public init?(iso: String) {
        let parts = iso.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, let date = Self.utc.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) else {
            return nil
        }
        self.init(date, in: Self.utc)
        guard self.iso == iso else { return nil }
    }

    private init(year: Int, month: Int, day: Int) {
        iso = String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// Midnight of this day in `calendar`'s time zone.
    public func start(in calendar: Calendar) -> Date {
        calendar.date(from: components)!
    }

    /// 1 = Sunday … 7 = Saturday, like the indices of `Calendar.weekdaySymbols` plus one.
    public var weekday: Int {
        Self.utc.component(.weekday, from: utcDate)
    }

    private var components: DateComponents {
        let parts = iso.split(separator: "-").map { Int($0)! }
        return DateComponents(year: parts[0], month: parts[1], day: parts[2])
    }

    private var utcDate: Date {
        Self.utc.date(from: components)!
    }

    private static let utc = Calendar.gregorian(in: TimeZone(identifier: "UTC")!)
}

extension LocalDay: Strideable {
    public func advanced(by days: Int) -> LocalDay {
        LocalDay(Self.utc.date(byAdding: .day, value: days, to: utcDate)!, in: Self.utc)
    }

    public func distance(to other: LocalDay) -> Int {
        Self.utc.dateComponents([.day], from: utcDate, to: other.utcDate).day!
    }

    public static func < (lhs: LocalDay, rhs: LocalDay) -> Bool {
        lhs.iso < rhs.iso
    }
}

extension LocalDay: Codable {
    public init(from decoder: Decoder) throws {
        let iso = try decoder.singleValueContainer().decode(String.self)
        guard let day = LocalDay(iso: iso) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Not a yyyy-MM-dd day: \(iso)"))
        }
        self = day
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(iso)
    }
}

extension LocalDay: CodingKeyRepresentable {
    public var codingKey: CodingKey { DayKey(stringValue: iso) }

    public init?<Key: CodingKey>(codingKey: Key) {
        self.init(iso: codingKey.stringValue)
    }

    private struct DayKey: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }

        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }
}
