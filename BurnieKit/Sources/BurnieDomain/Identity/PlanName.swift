import Foundation

/// The user's subscription as its chip shows it (`"MAX"`, `"PRO+"`). Encodes as the bare string.
public struct PlanName: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
