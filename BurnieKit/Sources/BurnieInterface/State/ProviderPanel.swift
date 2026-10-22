import BurnieDomain
import Foundation

/// One provider as the views see it.
public struct ProviderPanel: Equatable, Sendable {
    /// Equal by id.
    public let descriptor: ProviderDescriptor
    public var isEnabled: Bool
    /// Whether it's the effective favorite, the one the ring follows.
    public var isFavorite: Bool
    /// Without the features the user switched off.
    public var state: ProviderState
    /// The renewal's failed copy; nil when Burnie can't renew this provider's sign-in (B-22).
    public var renewalFailedCopy: String?
    /// Where the provider reads from (`"~/.claude"`), if anywhere.
    public var sourceLocation: String?

    public init(
        descriptor: ProviderDescriptor,
        isEnabled: Bool,
        isFavorite: Bool,
        state: ProviderState,
        renewalFailedCopy: String?,
        sourceLocation: String?
    ) {
        self.descriptor = descriptor
        self.isEnabled = isEnabled
        self.isFavorite = isFavorite
        self.state = state
        self.renewalFailedCopy = renewalFailedCopy
        self.sourceLocation = sourceLocation
    }

    public var id: ProviderID {
        descriptor.id
    }
}
