import BurnieDomain
import Foundation

/// A footer link to the provider's usage page (B-75).
public struct OpenDashboard: Sendable {
    private let action: @MainActor @Sendable (ProviderID) -> Void

    public init(_ action: @escaping @MainActor @Sendable (ProviderID) -> Void) {
        self.action = action
    }

    @MainActor
    public func callAsFunction(_ provider: ProviderID) {
        action(provider)
    }
}
