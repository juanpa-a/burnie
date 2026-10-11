import Testing
@testable import BurnieCore

struct RingStateLabelTests {
    @Test func flameAloneReadsAsBurnieUsage() {
        #expect(RingState.hidden.accessibilityLabel == "Burnie usage")
    }

    @Test func ringReadsTheFavoriteAndItsPercent() {
        #expect(RingState.visible(.claude, fraction: 0.64).accessibilityLabel == "Burnie usage, Claude Code 64%")
    }
}
