import Foundation

public enum MeterValue: Codable, Sendable, Equatable {
    /// "64%"
    case percent(Int)
    /// "$13.40 / $20"; a nil `limitCents` shows as "No limit".
    case money(usedCents: Int, limitCents: Int?)
}
