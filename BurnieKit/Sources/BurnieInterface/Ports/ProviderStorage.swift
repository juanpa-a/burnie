import Foundation

/// One provider's private JSON files, bound to its id by the composition root. Only for memos: losing a file only costs
/// time (P-5).
public protocol ProviderStorage: Sendable {
    /// nil when the file is missing or doesn't decode.
    func load<Value: Decodable>(_ type: Value.Type, named name: String) -> Value?
    /// A failed save is ignored: the next one retries.
    func save<Value: Encodable>(_ value: Value, named name: String)
}
