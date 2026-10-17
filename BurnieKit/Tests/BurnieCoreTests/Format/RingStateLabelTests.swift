import Testing
@testable import BurnieCore

struct RingStateLabelTests {
    @Test("B-54 VoiceOver reads the flame alone as Burnie usage")
    func flameAloneReadsAsBurnieUsage() {
        #expect(RingState.hidden.accessibilityLabel == "Burnie usage")
    }

    @Test("B-54 VoiceOver reads the ring's provider and percent")
    func ringReadsTheFavoriteAndItsPercent() {
        #expect(RingState.visible(.claude, fraction: 0.64).accessibilityLabel == "Burnie usage, Claude Code 64%")
    }
}
