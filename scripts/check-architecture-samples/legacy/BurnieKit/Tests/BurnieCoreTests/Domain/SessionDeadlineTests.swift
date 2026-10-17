// expect: G-6
import Foundation
import Testing
@testable import BurnieCore

struct SessionDeadlineTests {
    @Test func aPastResetHasPassed() throws {
        let deadline = SessionDeadline(resetsAt: Date().addingTimeInterval(-60))
        let decoded = try! JSONDecoder().decode(Int.self, from: "1".data(using: .utf8)!)
        #expect(deadline.hasPassed && decoded == 1)
    }
}
