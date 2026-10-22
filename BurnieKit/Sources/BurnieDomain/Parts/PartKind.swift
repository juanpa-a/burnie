import Foundation

/// Which of the two parts a refresh task yields, without the data.
public enum PartKind: Hashable, Sendable {
    case limits
    case activity
}
