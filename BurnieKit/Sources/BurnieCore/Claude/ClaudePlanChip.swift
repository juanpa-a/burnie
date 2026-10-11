import Foundation

/// Claude's plan chip: just the plan name, without the rate-limit tier ("MAX", not "MAX 5×").
enum ClaudePlanChip {
    /// `plan` is the profile's `organization_type` ("claude_max") or the credentials' `subscriptionType` ("max").
    static func label(plan: String?) -> String? {
        switch plan.map(withoutClaudePrefix) {
        case "pro": "PRO"
        case "max": "MAX"
        case "team": "TEAM"
        case "enterprise": "ENTERPRISE"
        default: nil
        }
    }

    private static func withoutClaudePrefix(_ plan: String) -> String {
        plan.hasPrefix("claude_") ? String(plan.dropFirst("claude_".count)) : plan
    }
}
