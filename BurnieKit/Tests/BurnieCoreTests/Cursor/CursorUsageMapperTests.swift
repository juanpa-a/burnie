import Foundation
import Testing
@testable import BurnieCore

struct CursorUsageMapperTests {
    static let cycleEnd = Date.iso("2026-11-01T00:00:00Z")
    static let pools = [
        Meter(id: .cursorModels, fraction: 0.3525, value: .percent(35), caption: .cycleEnds(cycleEnd)),
        Meter(id: .otherModels, fraction: 0.8, value: .percent(80), caption: .cycleEnds(cycleEnd)),
    ]

    func limits(_ fixture: String) throws -> LimitsReading {
        try CursorUsageMapper.limits(from: JSONDecoder().decode(CursorUsageSummaryDTO.self, from: Fixture.data(fixture)))
    }

    @Test func proShowsBothPoolsLikeTheDashboard() throws {
        #expect(try limits("cursor-summary-pro.json") == LimitsReading(plan: "PRO", meters: Self.pools))
    }

    @Test func enabledOnDemandAddsAMoneyMeter() throws {
        let onDemand = Meter(id: .onDemand, fraction: 0.248, value: .money(usedCents: 1_240, limitCents: 5_000), caption: .cycleEnds(Self.cycleEnd))
        #expect(try limits("cursor-summary-on-demand.json").meters == Self.pools + [onDemand])
    }

    @Test func onDemandWithoutLimitHasAnEmptyBar() throws {
        let onDemand = Meter(id: .onDemand, fraction: 0, value: .money(usedCents: 0, limitCents: nil), caption: .onDemandIdle)
        #expect(try limits("cursor-summary-unlimited.json").meters.last == onDemand)
    }

    @Test func freeShowsPoolsWithoutOnDemand() throws {
        let reading = try limits("cursor-summary-free.json")
        #expect(reading.plan == "FREE")
        #expect(reading.meters.map(\.value) == [.percent(12), .percent(0)])
    }

    @Test func teamPlanWithoutPoolsShowsOneUsageLimitMeter() throws {
        let meter = Meter(id: .included, fraction: 0.67, value: .money(usedCents: 1_340, limitCents: 2_000), caption: .cycleEnds(.iso("2026-11-01T00:00:00Z")))
        #expect(try limits("cursor-summary-team.json") == LimitsReading(plan: "ENTERPRISE", meters: [meter]))
    }

    @Test func singleMeterPrefersTheReportedPercentage() throws {
        let json = #"{"billingCycleEnd":"2026-11-01T00:00:00Z","individualUsage":{"plan":{"used":500,"limit":2000,"totalPercentUsed":40}}}"#
        let reading = try CursorUsageMapper.limits(from: JSONDecoder().decode(CursorUsageSummaryDTO.self, from: Data(json.utf8)))
        #expect(reading.meters.first?.fraction == 0.4)
    }

    @Test func summaryWithoutBucketsOrCycleIsUnexpected() throws {
        let decoder = JSONDecoder()
        let noBuckets = try decoder.decode(CursorUsageSummaryDTO.self, from: Data(#"{"billingCycleEnd":"2026-11-01T00:00:00Z","teamUsage":{}}"#.utf8))
        #expect(throws: ProviderIssue.unexpectedResponse("Cursor summary without usage buckets")) { try CursorUsageMapper.limits(from: noBuckets) }
        let noCycle = try decoder.decode(CursorUsageSummaryDTO.self, from: Data(#"{"individualUsage":{"plan":{"used":1}}}"#.utf8))
        #expect(throws: ProviderIssue.unexpectedResponse("Cursor summary without billing cycle end")) { try CursorUsageMapper.limits(from: noCycle) }
    }
}
