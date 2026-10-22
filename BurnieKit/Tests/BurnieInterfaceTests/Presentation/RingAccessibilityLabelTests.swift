import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInterface

struct RingAccessibilityLabelTests {
    let providers = [PanelSamples.panel(.alpha), PanelSamples.panel(.beta)]

    @Test("B-54 VoiceOver reads the flame alone as Burnie usage")
    func flameAloneReadsAsBurnieUsage() {
        #expect(RingAccessibilityLabel.text(for: .hidden, providers: providers) == "Burnie usage")
    }

    @Test("B-54 VoiceOver reads the ring's provider and percent")
    func ringReadsTheFavoriteAndItsPercent() {
        #expect(RingAccessibilityLabel.text(for: .visible(.alpha, percent: 64), providers: providers) == "Burnie usage, Alpha Code 64%")
    }
}
