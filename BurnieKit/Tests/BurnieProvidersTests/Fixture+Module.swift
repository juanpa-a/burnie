import BurnieTestSupport
import Foundation

/// This target's fixtures, from its `Fixtures` folder.
extension Fixture {
    static func data(_ name: String) -> Data {
        data(name, in: .module)
    }

    static func text(_ name: String) -> String {
        text(name, in: .module)
    }

    /// A file of SPEC section 12 from `Fixtures/Persistence`, decoded the way the app's file store reads it back:
    /// dates as seconds since 1970.
    static func persisted<Value: Decodable>(_ type: Value.Type, from name: String) throws -> Value {
        try JSONDecoder.persistence.decode(type, from: data("Persistence/" + name))
    }
}
