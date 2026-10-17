import Foundation

/// The stable key of a meter kind (`"session"`, `"cursorModels"`), declared by its provider. Encodes as the bare string.
public struct MeterID: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
