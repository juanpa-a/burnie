import BurnieDomain
import Foundation

/// Tracks or stops tracking a provider. Turning one off keeps its cache and history (B-51).
public struct SetProviderEnabled: Sendable {
    private let action: @MainActor @Sendable (ProviderID, Bool) -> Void

    public init(_ action: @escaping @MainActor @Sendable (ProviderID, Bool) -> Void) {
        self.action = action
    }

    @MainActor
    public func callAsFunction(_ provider: ProviderID, _ isEnabled: Bool) {
        action(provider, isEnabled)
    }
}
