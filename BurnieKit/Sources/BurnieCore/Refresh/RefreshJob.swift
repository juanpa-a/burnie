import Foundation

/// One source of one provider: what the scheduler refreshes at its own pace.
public struct RefreshJob: Hashable, Sendable {
    public let provider: ProviderID
    public let source: UsageSource

    public init(provider: ProviderID, source: UsageSource) {
        self.provider = provider
        self.source = source
    }
}
