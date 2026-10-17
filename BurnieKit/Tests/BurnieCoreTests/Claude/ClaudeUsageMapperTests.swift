import Foundation
import Testing
import LegacyTestSupport
@testable import BurnieCore

struct ClaudeUsageMapperTests {
    func meters(_ json: Data) throws -> [Meter] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try ClaudeUsageMapper.meters(from: decoder.decode(ClaudeUsageDTO.self, from: json))
    }

    static let sessionReset = Date.iso("2026-10-11T07:00:00.123456Z")
    static let weeklyReset = Date.iso("2026-10-16T18:00:00.654321Z")
    static let fixtureMeters = [
        Meter(
            id: .session, fraction: 0.23, value: .percent(23), caption: .resetsIn(sessionReset),
            period: DateInterval(start: sessionReset.addingTimeInterval(-5 * 3_600), duration: 5 * 3_600)
        ),
        Meter(
            id: .weekly, fraction: 0.41, value: .percent(41), caption: .resetsAt(weeklyReset),
            period: DateInterval(start: weeklyReset.addingTimeInterval(-7 * 86_400), duration: 7 * 86_400)
        ),
    ]

    @Test("B-49 session and weekly come from either shape of the usage response", arguments: [
        "claude-usage-both.json", "claude-usage-flat.json", "claude-usage-limits.json",
    ])
    func mapsSessionAndWeeklyFromEitherShape(fixture: String) throws {
        #expect(try meters(Fixture.data(fixture)) == Self.fixtureMeters)
    }

    @Test("B-49 the session lasts 5 hours and the week 7 days, up to their reset")
    func sessionLastsFiveHoursAndWeeklyAWeekUpToTheirReset() throws {
        let json = #"{"five_hour":{"utilization":10,"resets_at":"2026-10-11T07:00:00Z"},"seven_day":{"utilization":20,"resets_at":"2026-10-16T18:00:00Z"}}"#
        #expect(try meters(Data(json.utf8)).map(\.period) == [
            DateInterval(start: .iso("2026-10-11T02:00:00Z"), end: .iso("2026-10-11T07:00:00Z")),
            DateInterval(start: .iso("2026-10-09T18:00:00Z"), end: .iso("2026-10-16T18:00:00Z")),
        ])
    }

    @Test("B-49 limits[] wins over the flat windows")
    func prefersLimitsWhenBothShapesDisagree() throws {
        let json = #"{"five_hour":{"utilization":50,"resets_at":null},"limits":[{"kind":"session","percent":12,"resets_at":null}]}"#
        #expect(try meters(Data(json.utf8)).first?.value == .percent(12))
    }

    @Test("B-49 a session without reset shows no active session")
    func sessionWithoutResetHasNoActiveSession() throws {
        let session = try meters(Fixture.data("claude-usage-no-session.json")).first
        #expect(session == Meter(id: .session, fraction: 0, value: .percent(0), caption: .noActiveSession))
    }

    @Test("B-49 a weekly window without reset shows no active session")
    func weeklyWithoutResetHasNoActiveSession() throws {
        let json = #"{"seven_day":{"utilization":5,"resets_at":null}}"#
        #expect(try meters(Data(json.utf8)) == [Meter(id: .weekly, fraction: 0.05, value: .percent(5), caption: .noActiveSession)])
    }

    @Test("B-2 percentages outside 0–100 are clamped")
    func clampsPercentagesOutsideZeroToHundred() throws {
        let json = #"{"five_hour":{"utilization":104.4,"resets_at":null},"seven_day":{"utilization":-3,"resets_at":"2026-10-16T18:00:00Z"}}"#
        let mapped = try meters(Data(json.utf8))
        #expect(mapped.map(\.value) == [.percent(100), .percent(0)])
        #expect(mapped.map(\.fraction) == [1, 0])
    }

    @Test("B-49 a response without windows is unexpected")
    func responseWithoutWindowsIsUnexpected() {
        #expect(throws: ProviderIssue.unexpectedResponse("Claude usage without windows")) {
            try meters(Data(#"{"seven_day_opus":null,"limits":[]}"#.utf8))
        }
    }
}
