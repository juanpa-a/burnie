import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import SwiftUI
import Testing
@testable import BurnieComponents

/// The colors a meter's bar draws, read off its rendered pixels.
@MainActor
struct MeterViewTests {
    static let width: CGFloat = 340
    /// A full bar, half of it on pace and half past it, so each stretch draws its own color.
    static let fill = Fraction(1)
    static let pace = Fraction(0.5)
    static let overPace = Fraction(0.5)
    /// The middle of each stretch, clear of the rounded ends and the pace tick.
    static let onPaceX = Int(width * pace.value / 2)
    static let overPaceX = Int(width * (pace.value + fill.value) / 2)

    @Test("B-6 a stale meter fades its whole bar, so the over-pace color doesn't show through the accent", arguments: [ColorScheme.light, .dark])
    func staleBarFadesAsOne(scheme: ColorScheme) throws {
        let fresh = try #require(RenderedImage(meter(isStale: false).environment(\.colorScheme, scheme), width: Self.width))
        let stale = try #require(RenderedImage(meter(isStale: true).environment(\.colorScheme, scheme), width: Self.width))
        // Without a caption, the bar is the meter's bottom edge.
        let barMiddle = Int(fresh.size.height) - 1 - Int(DesignTokens.Metrics.meterBarHeight) / 2
        for x in [Self.onPaceX, Self.overPaceX] {
            let expected = fresh.color(atX: x, y: barMiddle).faded(by: DesignTokens.Opacity.stale)
            let drawn = stale.color(atX: x, y: barMiddle)
            #expect(drawn.isClose(to: expected), "\(scheme) at x \(x): drew \(drawn), expected \(expected)")
        }
    }

    private func meter(isStale: Bool) -> MeterView {
        MeterView(
            label: "Budget", value: nil, fill: Self.fill, pace: Self.pace, overPace: Self.overPace, caption: nil,
            accent: ProviderDescriptor.beta.color, isStale: isStale
        )
    }
}
