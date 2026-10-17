import BurnieDomain
import Foundation

/// One refresh task of one provider, as the runtime tracks it.
struct JobKey: Hashable, Sendable {
    let provider: ProviderID
    /// The task's name, unique within its provider.
    let task: String
}
