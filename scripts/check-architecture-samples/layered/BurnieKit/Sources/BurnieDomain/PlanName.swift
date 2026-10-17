// expect: D-6
/// Copy beside an allowed raw value or inside a format string is still copy.
public struct PlanName: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var chip: String { "Plan: " + rawValue }
    public var summary: String { String(format: "%d tokens today", rawValue.count) }
}
