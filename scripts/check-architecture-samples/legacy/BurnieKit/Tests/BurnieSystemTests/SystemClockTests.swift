// expect: none
import Foundation
import Testing
@testable import BurnieSystem

struct SystemClockTests {
    @Test func readsTheRealTime() {
        #expect(abs(SystemClock().now.timeIntervalSince(Date())) < 1)
    }
}
