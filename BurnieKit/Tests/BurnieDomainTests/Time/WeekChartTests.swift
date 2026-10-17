import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct WeekChartTests {
    static let today = LocalDay.day("2026-10-10")

    @Test("B-43 the week chart reads the 7 days ending today, zero-filled, with one shared peak")
    func readsTheSevenDaysEndingToday() {
        var history = UsageHistory()
        history.record([.day("2026-10-08"): Tokens(400), Self.today: Tokens(9)], for: .alpha, today: Self.today)
        history.record([Self.today: Tokens(1_000)], for: .beta, today: Self.today)

        let chart = WeekChart.make(history: history, providers: [.beta, .alpha], today: Self.today)
        #expect(chart.days.map(\.iso) == ["2026-10-04", "2026-10-05", "2026-10-06", "2026-10-07", "2026-10-08", "2026-10-09", "2026-10-10"])
        #expect(chart.providers == [.beta, .alpha])
        #expect(chart.series[.alpha]?.map(\.count) == [0, 0, 0, 0, 400, 0, 9])
        #expect(chart.peak == Tokens(1_000))
    }

    @Test("B-43 the chart rolls over with the day it's made for")
    func rollsOverWithToday() {
        let chart = WeekChart.make(history: UsageHistory(), providers: [.alpha], today: Self.today.advanced(by: 1))
        #expect(chart.days.last == Self.today.advanced(by: 1))
    }

    @Test(arguments: Gen.seeds(200))
    func everySeriesHasOneValuePerDay(seed: UInt64) {
        var gen = Gen(seed: seed)
        var history = UsageHistory()
        for _ in 0..<gen.int(in: 0...4) {
            history.record(gen.activityPart().tokens, for: gen.providerID(), today: gen.localDay())
        }
        let providers = (0..<gen.int(in: 0...3)).map { _ in gen.providerID() }
        let today = gen.localDay()
        let chart = WeekChart.make(history: history, providers: providers, today: today)

        #expect(chart.days.count == WeekChart.dayCount && chart.days.last == today, "seed \(seed)")
        #expect(zip(chart.days, chart.days.dropFirst()).allSatisfy { $0.advanced(by: 1) == $1 }, "seed \(seed)")
        #expect(chart.providers == providers, "seed \(seed)")
        #expect(providers.allSatisfy { chart.series[$0]?.count == WeekChart.dayCount }, "seed \(seed)")
        #expect(chart.peak == (chart.series.values.flatMap { $0 }.max() ?? .zero), "seed \(seed)")
    }
}
