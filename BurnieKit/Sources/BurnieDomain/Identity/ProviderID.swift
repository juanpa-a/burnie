import Foundation

/// The stable key of a provider (`"claude"`, `"cursor"`), used in settings and file names.
///
/// A newtype, not an enum: each provider declares its own constant inside `BurnieProviders`, so nothing outside it can
/// switch on a provider. Encodes as the bare string and works as a JSON object key.
public struct ProviderID: RawRepresentable, Hashable, Codable, CodingKeyRepresentable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
