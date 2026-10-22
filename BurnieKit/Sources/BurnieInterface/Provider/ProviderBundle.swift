import Foundation

/// What a provider hands the composition root: its descriptor, its capabilities and its refresh tasks, at most one
/// per part kind.
public struct ProviderBundle: Sendable {
    public let descriptor: ProviderDescriptor
    public let capabilities: ProviderCapabilities
    public let tasks: [RefreshTask]

    public init(descriptor: ProviderDescriptor, capabilities: ProviderCapabilities, tasks: [RefreshTask]) {
        self.descriptor = descriptor
        self.capabilities = capabilities
        self.tasks = tasks
    }
}
