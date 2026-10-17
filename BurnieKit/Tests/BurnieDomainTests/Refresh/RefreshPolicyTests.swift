import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct RefreshPolicyTests {
    let now = Date.iso("2026-10-10T20:00:00Z")
    let limits = RefreshPolicy(interval: 300, jitter: 30, staleOnOpen: 60, needsNetwork: true)
    let watchedActivity = RefreshPolicy(interval: 300, jitter: 0, staleOnOpen: nil, needsNetwork: false)

    @Test("B-31 opening the popover runs only tasks older than their staleness on open")
    func openingThePopoverRunsOnlyStaleTasks() {
        #expect(limits.shouldRun(for: .popoverOpened, lastRun: now.addingTimeInterval(-61), now: now))
        #expect(!limits.shouldRun(for: .popoverOpened, lastRun: now.addingTimeInterval(-30), now: now))
        #expect(limits.shouldRun(for: .popoverOpened, lastRun: nil, now: now))
    }

    @Test("B-31 opening the popover never runs a task without staleness on open")
    func openingThePopoverSkipsTasksWithoutStaleness() {
        #expect(!watchedActivity.shouldRun(for: .popoverOpened, lastRun: nil, now: now))
    }

    @Test("B-31 network restored runs only tasks older than their interval")
    func networkRestoredRunsOnlyOverdueTasks() {
        #expect(limits.shouldRun(for: .networkRestored, lastRun: now.addingTimeInterval(-301), now: now))
        #expect(!limits.shouldRun(for: .networkRestored, lastRun: now.addingTimeInterval(-120), now: now))
    }

    @Test("B-31 timer, manual, wake and activity changed always run", arguments: [RefreshTrigger.manual, .wake, .timer, .activityChanged])
    func otherTriggersIgnoreAge(trigger: RefreshTrigger) {
        #expect(limits.shouldRun(for: trigger, lastRun: now, now: now))
        #expect(watchedActivity.shouldRun(for: trigger, lastRun: now, now: now))
    }
}
