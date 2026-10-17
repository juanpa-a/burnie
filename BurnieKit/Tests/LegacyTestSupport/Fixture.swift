import Foundation

/// A test target's fixtures: the files of its `Fixtures` folder, copied as resources (`.copy("Fixtures")`).
/// Each target keeps its own, so the caller passes its bundle (`Bundle.module`).
public enum Fixture {
    public static func data(_ name: String, in bundle: Bundle) -> Data {
        guard let url = bundle.url(forResource: name, withExtension: nil, subdirectory: "Fixtures"),
              let data = try? Data(contentsOf: url)
        else { fatalError("No fixture named \(name)") }
        return data
    }

    public static func text(_ name: String, in bundle: Bundle) -> String {
        String(decoding: data(name, in: bundle), as: UTF8.self)
    }
}
