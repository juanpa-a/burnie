// expect: none
import BurnieInterface

/// Every port and provider bundle the composition root hands over.
public struct AppEnvironment: Sendable {
    public let clock: any Clock
    public let bundles: [ProviderBundle]

    public init(clock: any Clock, bundles: [ProviderBundle]) {
        self.clock = clock
        self.bundles = bundles
    }
}
