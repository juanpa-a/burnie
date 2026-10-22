import BurnieTestSupport
import Foundation

/// This target's fixtures, from its `Fixtures` folder.
extension Fixture {
    static func data(_ name: String) -> Data {
        data(name, in: .module)
    }

    /// A file of SPEC section 12 from `Fixtures/Persistence`, decoded the way the app's file store reads it back:
    /// dates as seconds since 1970.
    static func persisted<Value: Decodable>(_ type: Value.Type, from name: String) throws -> Value {
        try JSONDecoder.persistence.decode(type, from: data("Persistence/" + name))
    }

    /// Whether `value`, saved the way the app's file store saves it, is the same JSON as the persistence file `name`,
    /// whatever the order of the keys.
    static func persisted<Value: Encodable>(_ value: Value, matches name: String) throws -> Bool {
        let saved = try JSONSerialization.jsonObject(with: JSONEncoder.persistence.encode(value))
        let pinned = try JSONSerialization.jsonObject(with: data("Persistence/" + name))
        return (saved as? NSDictionary) == (pinned as? NSDictionary)
    }
}
