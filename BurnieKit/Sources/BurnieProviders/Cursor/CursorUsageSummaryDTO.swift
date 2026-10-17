import Foundation

/// Response of `cursor.com/api/usage-summary`. Amounts in cents; everything is optional.
struct CursorUsageSummaryDTO: Decodable {
    struct Bucket: Decodable {
        let enabled: Bool?
        let used: Int?
        /// nil = no limit.
        let limit: Int?
        let remaining: Int?
        /// Cursor Models pool (Auto, Composer), 0–100.
        let autoPercentUsed: Double?
        /// Other Models pool, 0–100.
        let apiPercentUsed: Double?
        /// 0–100
        let totalPercentUsed: Double?
    }

    struct Individual: Decodable {
        let plan: Bucket?
        let onDemand: Bucket?
        let overall: Bucket?
    }

    struct Team: Decodable {
        let onDemand: Bucket?
        let pooled: Bucket?
    }

    let billingCycleStart: String?
    let billingCycleEnd: String?
    /// "free", "pro", "pro_plus", "ultra", "business", "team", "enterprise"…
    let membershipType: String?
    let isUnlimited: Bool?
    let individualUsage: Individual?
    let teamUsage: Team?
}
