import Foundation

extension KeyedEncodingContainer {
    /// Saves a case without payload the way SPEC section 12 asks: its name holding an empty object, `{"offline": {}}`.
    mutating func encodeEmptyCase(_ key: Key) {
        _ = nestedContainer(keyedBy: Key.self, forKey: key)
    }
}
