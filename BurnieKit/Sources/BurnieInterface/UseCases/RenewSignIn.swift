import BurnieDomain
import Foundation

/// The expired sign-in's button: the provider's own app renews it, then its limits refresh (B-23). Returns false at once
/// for a provider that is off or can't renew, and false when its app couldn't renew.
public struct RenewSignIn: Sendable {
    private let action: @MainActor @Sendable (ProviderID) async -> Bool

    public init(_ action: @escaping @MainActor @Sendable (ProviderID) async -> Bool) {
        self.action = action
    }

    @MainActor
    public func callAsFunction(_ provider: ProviderID) async -> Bool {
        await action(provider)
    }
}
