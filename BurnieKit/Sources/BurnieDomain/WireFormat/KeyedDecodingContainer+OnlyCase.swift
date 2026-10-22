import Foundation

extension KeyedDecodingContainer {
    /// The case an enum was saved as. In the wire format of SPEC section 12 every enum is an object with one key, its
    /// case name; an object with none of the enum's cases, or with more than one, doesn't decode.
    func onlyCase() throws -> Key {
        guard allKeys.count == 1, let key = allKeys.first else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected exactly one known case"))
        }
        return key
    }
}
