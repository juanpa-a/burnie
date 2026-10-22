import Foundation

/// One measured limit: how full it is, what it reads, the line under it, whose usage it counts, and the window it fills
/// over.
public struct Meter: Hashable, Sendable, Identifiable {
    public let id: MeterID
    public let fill: Fraction
    public let value: MeterValue
    public let caption: MeterCaption
    public let scope: MeterScope
    /// The window the meter fills over, from its start to its reset; nil when there's none to pace against.
    public let period: DateInterval?

    public init(
        id: MeterID,
        fill: Fraction,
        value: MeterValue,
        caption: MeterCaption,
        scope: MeterScope = .own,
        period: DateInterval? = nil
    ) {
        self.id = id
        self.fill = fill
        self.value = value
        self.caption = caption
        self.scope = scope
        self.period = period
    }

    /// A percent meter from an API's 0–100 value: the fill and the shown percent clamp to 0…100, even if 104 or a
    /// negative arrives, and the percent rounds to a whole number (B-2).
    public static func percent(_ id: MeterID, used percentUsed: Double, caption: MeterCaption, period: DateInterval? = nil) -> Meter {
        let percent = percentUsed.isNaN ? 0 : min(max(percentUsed, 0), 100)
        return Meter(id: id, fill: Fraction(percent / 100), value: .percent(Int(percent.rounded())), caption: caption, period: period)
    }
}
