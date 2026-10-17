// expect: G-5
import BurnieDomain

/// Treats one provider apart, which only BurnieProviders may.
enum Reducer {
    static func needsNetwork(_ id: ProviderID) -> Bool {
        id == .cursor
    }
}
