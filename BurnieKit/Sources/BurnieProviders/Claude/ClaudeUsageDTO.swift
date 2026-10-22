import Foundation

/// Response of `api/oauth/usage`. It comes in two shapes, sometimes together; everything is optional
/// and unknown keys are ignored. Decoded with `.convertFromSnakeCase`.
struct ClaudeUsageDTO: Decodable {
    struct Window: Decodable {
        /// 0–100
        let utilization: Double?
        let resetsAt: String?
    }

    struct Limit: Decodable {
        /// "session" | "weekly_all" | "weekly_scoped"
        let kind: String?
        /// 0–100
        let percent: Double?
        let resetsAt: String?
    }

    let fiveHour: Window?
    let sevenDay: Window?
    let limits: [Limit]?
}
