// expect: G-5
import BurnieDomain

/// Puts one provider first by its raw id.
enum ProviderOrder {
    static func first(_ ids: [ProviderID]) -> ProviderID? {
        ids.first { $0.rawValue == "claude" }
    }
}
