import BurnieDomain
import Foundation

/// Cursor's plan chip from `membershipType` (B-9).
enum CursorPlanChip {
    static func label(membershipType: String?) -> PlanName? {
        guard let membershipType else { return nil }
        let label = switch membershipType {
        case "free": "FREE"
        case "pro": "PRO"
        case "pro_plus": "PRO+"
        case "ultra": "ULTRA"
        case "business", "team": "TEAMS"
        case "enterprise": "ENTERPRISE"
        default: membershipType.uppercased()
        }
        return PlanName(rawValue: label)
    }
}
