import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieProviders

struct CursorUsageMapperTests {
    static let cycleEnd = Date.iso("2026-11-01T00:00:00Z")
    static let cycle = DateInterval(start: .iso("2026-10-01T00:00:00Z"), end: cycleEnd)
    static let pools = MeterSet(
        primary: Meter(id: .cursorModels, fill: Fraction(0.3525), value: .percent(35), caption: .cycleEnds(cycleEnd), period: cycle),
        others: [Meter(id: .otherModels, fill: Fraction(0.8), value: .percent(80), caption: .cycleEnds(cycleEnd), period: cycle)]
    )

    func limits(_ fixture: String) throws -> LimitsPart {
        try CursorUsageMapper.limits(from: JSONDecoder().decode(CursorUsageSummaryDTO.self, from: Fixture.data(fixture)))
    }

    @Test("B-48 individual plans show Cursor Models and Other Models as percents, in tokens")
    func proShowsBothPoolsLikeTheDashboard() throws {
        #expect(try limits("cursor-summary-pro.json") == LimitsPart(plan: PlanName(rawValue: "PRO"), meters: Self.pools))
    }

    @Test("B-48 enabled on-demand comes as a money feature, drawn after the meters")
    func enabledOnDemandIsAMoneyFeature() throws {
        let onDemand = Meter(id: .onDemand, fill: Fraction(0.248), value: .money(used: Cents(1_240), limit: Cents(5_000)), caption: .cycleEnds(Self.cycleEnd))
        let limits = try limits("cursor-summary-on-demand.json")
        #expect(limits.meters == Self.pools)
        #expect(limits.features.onDemand == onDemand)
    }

    @Test("B-4 on-demand has no period, so it shows no pace tick")
    func onDemandHasNoPace() throws {
        let onDemand = try #require(try limits("cursor-summary-on-demand.json").features.onDemand)
        #expect(onDemand.id == .onDemand)
        #expect(onDemand.period == nil)
        #expect(onDemand.elapsedFraction(at: .iso("2026-10-15T00:00:00Z")) == nil)
    }

    @Test("B-48 unused on-demand without a limit has an empty bar and kicks in after included usage runs out")
    func onDemandWithoutLimitHasAnEmptyBar() throws {
        let onDemand = Meter(id: .onDemand, fill: .zero, value: .money(used: .zero, limit: nil), caption: .onDemandIdle)
        #expect(try limits("cursor-summary-unlimited.json").features.onDemand == onDemand)
    }

    @Test("B-48 a free plan shows both pools and no on-demand, which it hasn't enabled")
    func freeShowsPoolsWithoutOnDemand() throws {
        let reading = try limits("cursor-summary-free.json")
        #expect(reading.plan == PlanName(rawValue: "FREE"))
        #expect(reading.meters.all.map(\.value) == [.percent(12), .percent(0)])
        #expect(reading.features.onDemand == nil)
    }

    @Test("B-53 Cursor Models is primary on individual plans; Included usage, or the Team pool without it, on team plans")
    func primaryMeterFollowsThePlan() throws {
        #expect(try limits("cursor-summary-pro.json").meters.primary.id == .cursorModels)
        #expect(try limits("cursor-summary-enterprise.json").meters.primary.id == .included)
        #expect(try limits("cursor-summary-team.json").meters.primary.id == .teamPool)
    }

    @Test("B-48 a summary with only the team's pool shows it as the Team pool, scope team, in money")
    func teamPoolAloneShowsAsTheTeamPool() throws {
        let meter = Meter(
            id: .teamPool,
            fill: Fraction(0.67),
            value: .money(used: Cents(1_340), limit: Cents(2_000)),
            caption: .cycleEnds(Self.cycleEnd),
            scope: .team,
            period: Self.cycle
        )
        #expect(try limits("cursor-summary-team.json") == LimitsPart(plan: PlanName(rawValue: "ENTERPRISE"), meters: MeterSet(primary: meter)))
    }

    @Test("B-48 enterprise shows the member's own budget, not the team pool, and the team's on-demand as Team on-demand")
    func enterpriseShowsTheMembersOwnBudgetNotTheTeamPool() throws {
        let budget = Meter(id: .included, fill: Fraction(0.421), value: .money(used: Cents(4_210), limit: Cents(10_000)), caption: .cycleEnds(Self.cycleEnd), period: Self.cycle)
        let teamOnDemand = Meter(id: .teamOnDemand, fill: .zero, value: .money(used: .zero, limit: Cents(100_000)), caption: .onDemandIdle, scope: .team)
        let expected = LimitsPart(plan: PlanName(rawValue: "ENTERPRISE"), meters: MeterSet(primary: budget), features: SnapshotFeatures(onDemand: teamOnDemand))
        #expect(try limits("cursor-summary-enterprise.json") == expected)
    }

    @Test("B-48 the member's own on-demand comes before the team's, as On-demand of their own")
    func ownOnDemandComesBeforeTheTeams() throws {
        let json = #"""
        {"billingCycleEnd":"2026-11-01T00:00:00Z","individualUsage":{"overall":{"used":100,"limit":1000},"onDemand":{"enabled":true,"used":50,"limit":500}},
         "teamUsage":{"onDemand":{"enabled":true,"used":9000,"limit":90000}}}
        """#
        let onDemand = try #require(CursorUsageMapper.limits(from: JSONDecoder().decode(CursorUsageSummaryDTO.self, from: Data(json.utf8))).features.onDemand)
        #expect(onDemand.id == .onDemand)
        #expect(onDemand.scope == .own)
        #expect(onDemand.value == .money(used: Cents(50), limit: Cents(500)))
    }

    @Test("B-48 the Included usage meter fills to the reported percentage when there is one")
    func singleMeterPrefersTheReportedPercentage() throws {
        let json = #"{"billingCycleEnd":"2026-11-01T00:00:00Z","individualUsage":{"plan":{"used":500,"limit":2000,"totalPercentUsed":40}}}"#
        let reading = try CursorUsageMapper.limits(from: JSONDecoder().decode(CursorUsageSummaryDTO.self, from: Data(json.utf8)))
        #expect(reading.meters.primary.fill == Fraction(0.4))
    }

    @Test(arguments: [
        #"{"billingCycleEnd":"2026-11-01T00:00:00Z","individualUsage":{"plan":{"used":500,"limit":2000}}}"#,
        #"{"billingCycleStart":"2026-11-02T00:00:00Z","billingCycleEnd":"2026-11-01T00:00:00Z","individualUsage":{"plan":{"used":500,"limit":2000}}}"#,
    ])
    func cycleWithoutAValidStartHasNoPeriod(json: String) throws {
        let reading = try CursorUsageMapper.limits(from: JSONDecoder().decode(CursorUsageSummaryDTO.self, from: Data(json.utf8)))
        #expect(reading.meters.primary.period == nil)
    }

    @Test("B-48 a summary without usage buckets or billing cycle end is unexpected")
    func summaryWithoutBucketsOrCycleIsUnexpected() throws {
        let decoder = JSONDecoder()
        let noBuckets = try decoder.decode(CursorUsageSummaryDTO.self, from: Data(#"{"billingCycleEnd":"2026-11-01T00:00:00Z","teamUsage":{}}"#.utf8))
        #expect(throws: ProviderIssue.unexpectedResponse("Cursor summary without usage buckets")) { try CursorUsageMapper.limits(from: noBuckets) }
        let noCycle = try decoder.decode(CursorUsageSummaryDTO.self, from: Data(#"{"individualUsage":{"plan":{"used":1}}}"#.utf8))
        #expect(throws: ProviderIssue.unexpectedResponse("Cursor summary without billing cycle end")) { try CursorUsageMapper.limits(from: noCycle) }
    }
}
