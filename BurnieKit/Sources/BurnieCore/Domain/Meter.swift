import Foundation

public struct Meter: Codable, Sendable, Equatable, Identifiable {
    public let id: MeterID
    /// Always within 0...1: the initializer clamps even if the API sends 104%, negatives or NaN.
    public let fraction: Double
    public let value: MeterValue
    public let caption: MeterCaption
    /// The window the meter fills over, from its start to its reset; nil when there's none to pace against.
    public let period: DateInterval?

    public init(id: MeterID, fraction: Double, value: MeterValue, caption: MeterCaption, period: DateInterval? = nil) {
        self.id = id
        self.fraction = fraction.isNaN ? 0 : min(max(fraction, 0), 1)
        self.value = value
        self.caption = caption
        self.period = period
    }

    /// A percentage meter from an API's 0–100 value: "64%", clamped even if 104 or a negative arrives.
    static func percent(_ id: MeterID, used percentUsed: Double, caption: MeterCaption, period: DateInterval? = nil) -> Meter {
        let percent = min(max(percentUsed, 0), 100)
        return Meter(id: id, fraction: percent / 100, value: .percent(Int(percent.rounded())), caption: caption, period: period)
    }
}
