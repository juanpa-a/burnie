// expect: none
import BurnieDomain

/// Members whose names only start like a provider's aren't provider ids.
enum IssueRouting {
    static func isNotFound(_ issue: ProviderIssue) -> Bool {
        switch issue {
        case .claudeNotFound, .cursorless: true
        default: issue == .claudeNotFound
        }
    }
}
