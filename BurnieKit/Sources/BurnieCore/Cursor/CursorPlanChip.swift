import Foundation

/// Cursor's plan chip from `membershipType`.
enum CursorPlanChip {
    static func label(membershipType: String?) -> String? {
        guard let membershipType else { return nil }
        return switch membershipType {
        case "free": "FREE"
        case "pro": "PRO"
        case "pro_plus": "PRO+"
        case "ultra": "ULTRA"
        case "business", "team": "TEAMS"
        case "enterprise": "ENTERPRISE"
        default: membershipType.uppercased()
        }
    }
}
