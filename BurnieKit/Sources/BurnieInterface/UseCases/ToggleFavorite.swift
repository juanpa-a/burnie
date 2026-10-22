import BurnieDomain
import Foundation

/// The heart: one favorite at a time (B-52).
public struct ToggleFavorite: Sendable {
    private let action: @MainActor @Sendable (ProviderID) -> Void

    public init(_ action: @escaping @MainActor @Sendable (ProviderID) -> Void) {
        self.action = action
    }

    @MainActor
    public func callAsFunction(_ provider: ProviderID) {
        action(provider)
    }
}
