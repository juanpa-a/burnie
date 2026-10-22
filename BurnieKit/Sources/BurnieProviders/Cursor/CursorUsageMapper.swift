import BurnieDomain
import Foundation

/// From `CursorUsageSummaryDTO` to Cursor's limits part (B-48).
///
/// Individual plans: the Cursor Models and Other Models pools as percentages, like the dashboard; today reads in tokens.
/// Plans without pools (teams, enterprise): a single included usage meter in money; today reads in money.
/// On-demand is a feature, only when enabled, without a period: it has no pace to keep (B-4).
/// The member's own buckets come first; the team's stand in only without them, as team meters (scope team), so a
/// team's spend never reads as the member's.
enum CursorUsageMapper {
    static func limits(from summary: CursorUsageSummaryDTO) throws(ProviderIssue) -> LimitsPart {
        guard let cycleEnd = summary.billingCycleEnd.flatMap(ISO8601DateParser.date(from:)) else {
            throw .unexpectedResponse("Cursor summary without billing cycle end")
        }
        let period = billingCycle(start: summary.billingCycleStart, end: cycleEnd)
        let included = try includedUsage(in: summary, cycleEnd: cycleEnd, period: period)
        return LimitsPart(
            plan: CursorPlanChip.label(membershipType: summary.membershipType),
            meters: included.meters,
            unit: included.unit,
            features: SnapshotFeatures(onDemand: onDemandMeter(in: summary, cycleEnd: cycleEnd))
        )
    }

    /// Cursor Models is primary on individual plans; included usage on team and enterprise ones.
    private static func includedUsage(
        in summary: CursorUsageSummaryDTO,
        cycleEnd: Date,
        period: DateInterval?
    ) throws(ProviderIssue) -> (meters: MeterSet, unit: UsageUnit) {
        let individual = summary.individualUsage
        if let plan = individual?.plan, let cursorModels = plan.autoPercentUsed, let otherModels = plan.apiPercentUsed {
            let pools = MeterSet(
                primary: .percent(.cursorModels, used: cursorModels, caption: .cycleEnds(cycleEnd), period: period),
                others: [.percent(.otherModels, used: otherModels, caption: .cycleEnds(cycleEnd), period: period)]
            )
            return (pools, .tokens)
        }
        guard let (bucket, scope) = ownOrTeam(own: individual?.plan ?? individual?.overall, team: summary.teamUsage?.pooled),
              let used = bucket.used
        else {
            throw .unexpectedResponse("Cursor summary without usage buckets")
        }
        let budget = Meter(
            id: scope == .own ? .included : .teamPool,
            fill: bucket.totalPercentUsed.map { Fraction($0 / 100) } ?? share(used: used, of: bucket.limit),
            value: .money(used: Cents(used), limit: bucket.limit.map(Cents.init)),
            caption: .cycleEnds(cycleEnd),
            scope: scope,
            period: period
        )
        return (MeterSet(primary: budget), .money)
    }

    /// "Kicks in after included usage runs out" while nothing was spent (B-48).
    private static func onDemandMeter(in summary: CursorUsageSummaryDTO, cycleEnd: Date) -> Meter? {
        guard let (bucket, scope) = ownOrTeam(own: summary.individualUsage?.onDemand, team: summary.teamUsage?.onDemand),
              bucket.enabled == true
        else { return nil }
        let used = bucket.used ?? 0
        return Meter(
            id: scope == .own ? .onDemand : .teamOnDemand,
            fill: share(used: used, of: bucket.limit),
            value: .money(used: Cents(used), limit: bucket.limit.map(Cents.init)),
            caption: used == 0 ? .onDemandIdle : .cycleEnds(cycleEnd),
            scope: scope
        )
    }

    /// The member's own bucket when the summary has one, else the team's, with whose it is.
    private static func ownOrTeam(
        own: CursorUsageSummaryDTO.Bucket?,
        team: CursorUsageSummaryDTO.Bucket?
    ) -> (bucket: CursorUsageSummaryDTO.Bucket, scope: MeterScope)? {
        if let own { return (own, .own) }
        return team.map { ($0, .team) }
    }

    /// The whole billing cycle; nil if its start is missing or isn't before its end.
    private static func billingCycle(start: String?, end: Date) -> DateInterval? {
        guard let start = start.flatMap(ISO8601DateParser.date(from:)), start < end else { return nil }
        return DateInterval(start: start, end: end)
    }

    /// Without a limit, or with a limit of 0, the bar stays empty.
    private static func share(used: Int, of limit: Int?) -> Fraction {
        guard let limit, limit > 0 else { return .zero }
        return Fraction(Double(used) / Double(limit))
    }
}
