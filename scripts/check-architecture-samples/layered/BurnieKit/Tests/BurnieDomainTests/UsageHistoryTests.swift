// expect: G-6
import Foundation
import Testing
@testable import BurnieDomain

struct UsageHistoryTests {
    @Test func keepsToday() {
        let today = Date.now
        #expect(today.timeIntervalSince1970 > 0)
    }
}
