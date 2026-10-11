import Foundation

enum Fixture {
    static func data(_ name: String) -> Data {
        let url = Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures")!
        return try! Data(contentsOf: url)
    }

    static func text(_ name: String) -> String {
        String(decoding: data(name), as: UTF8.self)
    }
}
