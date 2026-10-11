import Foundation
import Testing
@testable import BurnieSystem

struct SystemClockTests {
    @Test func usesTheSystemTimeZone() {
        #expect(SystemClock().timeZone == .current)
    }
}
