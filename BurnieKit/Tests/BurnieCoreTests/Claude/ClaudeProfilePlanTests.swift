import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct ClaudeProfilePlanTests {
    let now = Date.iso("2026-10-11T02:00:00Z")
    let http = FakeHTTPClient(status: 200, body: Fixture.data("claude-profile.json"))

    @Test("B-28 the profile is asked at most once an hour")
    func asksTheProfileAtMostOncePerHour() async {
        let plan = ClaudeProfilePlan(http: http)
        #expect(await plan.chip(headers: [:], now: now) == "MAX")
        #expect(await plan.chip(headers: [:], now: now.addingTimeInterval(59 * 60)) == "MAX")
        #expect(http.requests.count == 1)
        _ = await plan.chip(headers: [:], now: now.addingTimeInterval(61 * 60))
        #expect(http.requests.count == 2)
    }

    @Test("B-28 a failed profile request keeps the last good plan")
    func keepsTheLastPlanWhenARefreshFails() async {
        let plan = ClaudeProfilePlan(http: http)
        _ = await plan.chip(headers: [:], now: now)
        http.respond(status: 429)
        #expect(await plan.chip(headers: [:], now: now.addingTimeInterval(2 * 60 * 60)) == "MAX")
    }

    @Test("B-28 without any profile answer there is no plan from it")
    func withoutAnAnswerThereIsNoPlan() async {
        http.respond(status: 401)
        #expect(await ClaudeProfilePlan(http: http).chip(headers: [:], now: now) == nil)
    }
}
