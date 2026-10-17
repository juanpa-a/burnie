import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct ActivityWindowTests {
    @Test("B-41 the activity window is today and the 7 days before")
    func activityWindowCoversTodayAndTheSevenDaysBefore() {
        let window = ActivityWindow.days(endingAt: .day("2026-10-10"))
        #expect(window.lowerBound.iso == "2026-10-03")
        #expect(window.count == 8)
    }
}
