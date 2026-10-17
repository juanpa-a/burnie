import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct LastUpdatedFormatterTests {
    let now = Date.iso("2026-10-10T18:00:00Z")

    @Test("B-55 the header says how old the data is", arguments: [
        (0.0, "Updated just now"),
        (59.0, "Updated just now"),
        (120.0, "Updated 2 min ago"),
        (3_599.0, "Updated 59 min ago"),
        (3_600.0, "Updated 1 h ago"),
        (10_800.0, "Updated 3 h ago"),
    ])
    func describesTheAgeOfTheData(age: TimeInterval, expected: String) {
        #expect(LastUpdatedFormatter().string(lastUpdated: now.addingTimeInterval(-age), now: now) == expected)
    }

    @Test("B-55 the header says Updating… before any data")
    func saysUpdatingWithoutData() {
        #expect(LastUpdatedFormatter().string(lastUpdated: nil, now: now) == "Updating…")
    }
}
