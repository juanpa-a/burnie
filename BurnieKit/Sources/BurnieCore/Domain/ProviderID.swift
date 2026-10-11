import Foundation

public enum ProviderID: String, Codable, CodingKeyRepresentable, CaseIterable, Sendable {
    case claude, cursor
}
