import Foundation
import Testing
@testable import BurnieInfra

struct SystemClockTests {
    @Test func usesTheSystemTimeZone() {
        #expect(SystemClock().timeZone == .current)
    }
}
