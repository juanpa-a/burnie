import BurnieDomain
import Foundation

/// What a provider's healthy status line is built from.
public struct StatusContext: Hashable, Sendable {
    /// The plan, if a snapshot has shown one.
    public let plan: PlanName?
    /// Where the provider reads from (`"~/.claude"`), if it reads local files.
    public let sourceLocation: String?

    public init(plan: PlanName?, sourceLocation: String?) {
        self.plan = plan
        self.sourceLocation = sourceLocation
    }
}
