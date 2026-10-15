import Foundation

/// From `CursorUsageSummaryDTO` to Cursor's meters and how the plan measures usage.
///
/// Individual plans: the Cursor Models and Other Models pools as percentages, like the dashboard; today reads in tokens.
/// Plans without pools (teams, enterprise): a single usage meter in money; today reads in money.
/// On-demand is added only when enabled, without a period: it has no pace to keep.
enum CursorUsageMapper {
    static func limits(from summary: CursorUsageSummaryDTO) throws(ProviderIssue) -> LimitsReading {
        guard let cycleEnd = summary.billingCycleEnd.flatMap(ISO8601DateParser.date(from:)) else {
            throw .unexpectedResponse("Cursor summary without billing cycle end")
        }
        let period = billingCycle(start: summary.billingCycleStart, end: cycleEnd)
        let included = try includedUsage(in: summary, cycleEnd: cycleEnd, period: period)
        let onDemand = onDemandMeter(in: summary, cycleEnd: cycleEnd)
        let plan = CursorPlanChip.label(membershipType: summary.membershipType)
        return LimitsReading(plan: plan, meters: included.meters + [onDemand].compactMap { $0 }, unit: included.unit)
    }

    private static func includedUsage(
        in summary: CursorUsageSummaryDTO,
        cycleEnd: Date,
        period: DateInterval?
    ) throws(ProviderIssue) -> (meters: [Meter], unit: UsageUnit) {
        let individual = summary.individualUsage
        if let plan = individual?.plan, let cursorModels = plan.autoPercentUsed, let otherModels = plan.apiPercentUsed {
            let pools: [Meter] = [
                .percent(.cursorModels, used: cursorModels, caption: .cycleEnds(cycleEnd), period: period),
                .percent(.otherModels, used: otherModels, caption: .cycleEnds(cycleEnd), period: period),
            ]
            return (pools, .tokens)
        }
        guard let bucket = individual?.plan ?? individual?.overall ?? summary.teamUsage?.pooled, let used = bucket.used else {
            throw .unexpectedResponse("Cursor summary without usage buckets")
        }
        let fraction = bucket.totalPercentUsed.map { $0 / 100 } ?? share(used: used, of: bucket.limit)
        let budget = Meter(
            id: .included,
            fraction: fraction,
            value: .money(usedCents: used, limitCents: bucket.limit),
            caption: .cycleEnds(cycleEnd),
            period: period
        )
        return ([budget], .money)
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

    /// The whole billing cycle; nil if its start is missing or isn't before its end.
    private static func billingCycle(start: String?, end: Date) -> DateInterval? {
        guard let start = start.flatMap(ISO8601DateParser.date(from:)), start < end else { return nil }
        return DateInterval(start: start, end: end)
    }

    /// Without a limit (or with a limit of 0) the bar stays empty.
    private static func share(used: Int, of limit: Int?) -> Double {
        guard let limit, limit > 0 else { return 0 }
        return Double(used) / Double(limit)
    }
}
