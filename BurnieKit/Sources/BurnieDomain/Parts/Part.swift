import Foundation

/// One piece of information a provider reports, with its data. How and where it gets it is the provider's business.
public enum Part: Hashable, Sendable {
    case limits(LimitsPart)
    case activity(ActivityPart)

    public var kind: PartKind {
        switch self {
        case .limits: .limits
        case .activity: .activity
        }
    }
}
