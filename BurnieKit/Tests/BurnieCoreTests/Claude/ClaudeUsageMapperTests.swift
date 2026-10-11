import Foundation
import Testing
@testable import BurnieCore

struct ClaudeUsageMapperTests {
    func meters(_ json: Data) throws -> [Meter] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try ClaudeUsageMapper.meters(from: decoder.decode(ClaudeUsageDTO.self, from: json))
    }

    static let fixtureMeters = [
        Meter(id: .session, fraction: 0.23, value: .percent(23), caption: .resetsIn(.iso("2026-10-11T07:00:00.123456Z"))),
        Meter(id: .weekly, fraction: 0.41, value: .percent(41), caption: .resetsAt(.iso("2026-10-16T18:00:00.654321Z"))),
    ]

    @Test(arguments: ["claude-usage-both.json", "claude-usage-flat.json", "claude-usage-limits.json"])
    func mapsSessionAndWeeklyFromEitherShape(fixture: String) throws {
        #expect(try meters(Fixture.data(fixture)) == Self.fixtureMeters)
    }

    @Test func prefersLimitsWhenBothShapesDisagree() throws {
        let json = #"{"five_hour":{"utilization":50,"resets_at":null},"limits":[{"kind":"session","percent":12,"resets_at":null}]}"#
        #expect(try meters(Data(json.utf8)).first?.value == .percent(12))
    }

    @Test func sessionWithoutResetHasNoActiveSession() throws {
        let session = try meters(Fixture.data("claude-usage-no-session.json")).first
        #expect(session == Meter(id: .session, fraction: 0, value: .percent(0), caption: .noActiveSession))
    }

    @Test func clampsPercentagesOutsideZeroToHundred() throws {
        let json = #"{"five_hour":{"utilization":104.4,"resets_at":null},"seven_day":{"utilization":-3,"resets_at":"2026-10-16T18:00:00Z"}}"#
        let mapped = try meters(Data(json.utf8))
        #expect(mapped.map(\.value) == [.percent(100), .percent(0)])
        #expect(mapped.map(\.fraction) == [1, 0])
    }

    @Test func responseWithoutWindowsIsUnexpected() {
        #expect(throws: ProviderIssue.unexpectedResponse("Claude usage without windows")) {
            try meters(Data(#"{"seven_day_opus":null,"limits":[]}"#.utf8))
        }
    }
}
