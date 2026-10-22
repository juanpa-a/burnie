import Foundation

extension JSONDecoder {
    /// Reads SPEC section 12's files as the app's file store does: dates as seconds since 1970.
    public static var persistence: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
}
