import Foundation

/// From `CursorUsageSummaryDTO` to Cursor's meters.
///
/// Individual plans: the Cursor Models and Other Models pools as percentages, like the dashboard.
/// Plans without pools (teams): a single usage meter in money. On-demand is added only when enabled.
enum CursorUsageMapper {
    static func limits(from summary: CursorUsageSummaryDTO) throws(ProviderIssue) -> LimitsReading {
        guard let cycleEnd = summary.billingCycleEnd.flatMap(ISO8601DateParser.date(from:)) else {
            throw .unexpectedResponse("Cursor summary without billing cycle end")
        }
        let included = try includedMeters(in: summary, cycleEnd: cycleEnd)
        let onDemand = onDemandMeter(in: summary, cycleEnd: cycleEnd)
        return LimitsReading(plan: CursorPlanChip.label(membershipType: summary.membershipType), meters: included + [onDemand].compactMap { $0 })
    }

    private static func includedMeters(in summary: CursorUsageSummaryDTO, cycleEnd: Date) throws(ProviderIssue) -> [Meter] {
        let individual = summary.individualUsage
        if let plan = individual?.plan, let cursorModels = plan.autoPercentUsed, let otherModels = plan.apiPercentUsed {
            return [
                .percent(.cursorModels, used: cursorModels, caption: .cycleEnds(cycleEnd)),
                .percent(.otherModels, used: otherModels, caption: .cycleEnds(cycleEnd)),
            ]
        }
        guard let bucket = individual?.plan ?? individual?.overall ?? summary.teamUsage?.pooled, let used = bucket.used else {
            throw .unexpectedResponse("Cursor summary without usage buckets")
        }
        let fraction = bucket.totalPercentUsed.map { $0 / 100 } ?? share(used: used, of: bucket.limit)
        return [Meter(id: .included, fraction: fraction, value: .money(usedCents: used, limitCents: bucket.limit), caption: .cycleEnds(cycleEnd))]
    }

    private static func onDemandMeter(in summary: CursorUsageSummaryDTO, cycleEnd: Date) -> Meter? {
        guard let bucket = summary.individualUsage?.onDemand ?? summary.teamUsage?.onDemand, bucket.enabled == true else { return nil }
        let used = bucket.used ?? 0
        return Meter(
            id: .onDemand,
            fraction: share(used: used, of: bucket.limit),
            value: .money(usedCents: used, limitCents: bucket.limit),
            caption: used == 0 ? .onDemandIdle : .cycleEnds(cycleEnd)
        )
    }

    /// Without a limit (or with a limit of 0) the bar stays empty.
    private static func share(used: Int, of limit: Int?) -> Double {
        guard let limit, limit > 0 else { return 0 }
        return Double(used) / Double(limit)
    }
}
