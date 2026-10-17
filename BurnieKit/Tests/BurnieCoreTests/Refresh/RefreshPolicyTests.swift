import Foundation
import Testing
import LegacyTestSupport
@testable import BurnieCore

struct RefreshPolicyTests {
    let now = Date.iso("2026-10-10T20:00:00Z")

    func policy(_ provider: ProviderID, _ source: UsageSource) -> RefreshPolicy {
        .standard(for: RefreshJob(provider: provider, source: source))
    }

    @Test("B-30 each source has its standard interval, jitter, staleness on open and network need")
    func eachSourceHasItsStandardRhythm() {
        #expect(policy(.claude, .limits) == RefreshPolicy(interval: 300, jitter: 30, staleOnOpen: 60, needsNetwork: true))
        #expect(policy(.claude, .activity) == RefreshPolicy(interval: 300, jitter: 0, staleOnOpen: nil, needsNetwork: false))
        #expect(policy(.cursor, .limits) == RefreshPolicy(interval: 600, jitter: 30, staleOnOpen: 60, needsNetwork: true))
        #expect(policy(.cursor, .activity) == RefreshPolicy(interval: 1_800, jitter: 0, staleOnOpen: 600, needsNetwork: true))
    }

    @Test("B-31 opening the popover runs only sources older than their staleness on open")
    func openingThePopoverRefreshesOnlyStaleSources() {
        let limits = policy(.claude, .limits)
        #expect(limits.shouldRun(for: .popoverOpened, lastRun: now.addingTimeInterval(-61), now: now))
        #expect(!limits.shouldRun(for: .popoverOpened, lastRun: now.addingTimeInterval(-30), now: now))
        #expect(!policy(.claude, .activity).shouldRun(for: .popoverOpened, lastRun: nil, now: now))
        #expect(!policy(.cursor, .activity).shouldRun(for: .popoverOpened, lastRun: now.addingTimeInterval(-300), now: now))
    }

    @Test("B-31 network restored runs only sources older than their interval")
    func networkRestoredRefreshesOnlyOverdueSources() {
        let limits = policy(.cursor, .limits)
        #expect(limits.shouldRun(for: .networkRestored, lastRun: now.addingTimeInterval(-601), now: now))
        #expect(!limits.shouldRun(for: .networkRestored, lastRun: now.addingTimeInterval(-120), now: now))
    }

    @Test("B-31 timer, manual, wake and activity changed always run", arguments: [RefreshTrigger.manual, .wake, .timer, .activityChanged])
    func otherTriggersIgnoreAge(trigger: RefreshTrigger) {
        #expect(policy(.cursor, .limits).shouldRun(for: trigger, lastRun: now, now: now))
    }
}
