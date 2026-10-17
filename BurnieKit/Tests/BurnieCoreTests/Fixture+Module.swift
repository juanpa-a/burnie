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
}
