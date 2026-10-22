import Foundation

/// An issue only one provider has, identified by a code it declares (Claude's `missingScope`). Its copy lives in the
/// provider's descriptor, so Domain stays free of copy. Encodes as the bare code.
public struct SpecificIssue: Hashable, Sendable {
    public let code: String

    public init(code: String) {
        self.code = code
    }
}

extension SpecificIssue: Codable {
    public init(from decoder: Decoder) throws {
        self.init(code: try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(code)
    }
}
