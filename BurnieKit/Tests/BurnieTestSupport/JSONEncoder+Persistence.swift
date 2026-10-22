import Foundation

extension JSONEncoder {
    /// Writes SPEC section 12's files as the app's file store does: dates as seconds since 1970, keys sorted.
    public static var persistence: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .sortedKeys
        return encoder
    }
}
