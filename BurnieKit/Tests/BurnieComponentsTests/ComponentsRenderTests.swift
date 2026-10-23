import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import SwiftUI
import Testing
@testable import BurnieComponents

/// Every component renders, at a non-zero size, in light and dark, with generated values and the edge states (T-9).
@MainActor
struct ComponentsRenderTests {
    static let accent = ProviderDescriptor.alpha.color

    @Test func basicPiecesRender() {
        #expect(RenderedSize.isDrawn(BurnieDivider()))
        #expect(RenderedSize.isDrawn(UpdateBadge(), width: 20))
        #expect(RenderedSize.isDrawn(PlanChip(plan: PlanName(rawValue: "MAX")), width: 60))
        #expect(RenderedSize.isDrawn(IssueRow(message: "Run `alpha` and log in again.")))
        #expect(RenderedSize.isDrawn(FooterItem(title: Copy.quit, accessory: .shortcut(Copy.quitShortcut)) {}))
        #expect(RenderedSize.isDrawn(FooterItem(title: "Open Alpha usage page", accessory: .external) {}))
    }

    @Test func buttonsRender() {
        #expect(RenderedSize.isDrawn(ChipButton(title: Copy.chooseProviders) {}, width: 160))
        #expect(RenderedSize.isDrawn(ChipButton(title: Copy.renewSignIn, isBusy: true) {}, width: 160))
        #expect(RenderedSize.isDrawn(IconButton(systemName: "arrow.clockwise", accessibilityLabel: Copy.refresh, isSpinning: true) {}, width: 40))
        #expect(RenderedSize.isDrawn(Toggle(Copy.launchAtLogin, isOn: .constant(true)).toggleStyle(BurnieSwitchStyle(onColor: .accentColor)), width: 60))
        #expect(RenderedSize.isDrawn(Button(Copy.quit) {}.buttonStyle(HoverHighlightStyle(cornerRadius: 6)), width: 60))
    }

    @Test func rowsRender() {
        #expect(RenderedSize.isDrawn(SwitchRow(title: Copy.ringInMenuBar, subtitle: Text(Copy.ringShows("Alpha Code")), isOn: .constant(true))))
        #expect(RenderedSize.isDrawn(SwitchRow(title: Copy.ringInMenuBar, subtitle: Text(Copy.ringShows("Alpha Code")), isOn: .constant(false)).disabled(true)))
        for isOn in [true, false] {
            let row = ProviderRow(displayName: "Alpha Code", status: "Off", accent: Self.accent, isFavorite: isOn, onToggleFavorite: {}, isOn: .constant(isOn))
            #expect(RenderedSize.isDrawn(row))
        }
        #expect(RenderedSize.isDrawn(SignInRenewalRow(message: "Alpha sign-in expired.", failedMessage: "Alpha couldn't renew.") { false }))
    }

    @Test("B-5 B-6 a meter renders loading, stale, without a pace and over its pace", arguments: Gen.seeds(20))
    func meterRenders(seed: UInt64) {
        var gen = Gen(seed: seed)
        let meter = gen.meter()
        let now = gen.date()
        let value = MeterValueFormatter(locale: .enUS).parts(for: meter.value)
        let caption = MeterCaptionFormatter(locale: .enUS, timeZone: .mexicoCity).string(for: meter.caption, now: now)
        let view = MeterView(
            label: ProviderDescriptor.alpha.label(for: meter.id),
            value: gen.coinFlip() ? value : nil,
            fill: meter.fill,
            pace: meter.elapsedFraction(at: now),
            overPace: meter.overPace(at: now),
            caption: gen.coinFlip() ? caption : nil,
            accent: Self.accent,
            isStale: gen.coinFlip()
        )
        #expect(RenderedSize.isDrawn(view), "seed \(seed)")
    }

    @Test("B-53 the menu bar icon renders the flame alone and inside every ring", arguments: [0, 1, 64, 100])
    func menuBarIconRenders(percent: Int) {
        #expect(RenderedSize.isDrawn(MenuBarIcon(ring: .hidden), width: 18))
        #expect(RenderedSize.isDrawn(MenuBarIcon(ring: .visible(.alpha, percent: percent)), width: 18))
    }

    @Test("B-43 the week chart renders empty and generated weeks, with one or two providers", arguments: Gen.seeds(20))
    func weekChartRenders(seed: UInt64) {
        var gen = Gen(seed: seed)
        var history = UsageHistory()
        let today = gen.localDay()
        if gen.coinFlip() {
            history.record(gen.activityPart(around: today).tokens, for: .alpha, today: today)
            history.record(gen.activityPart(around: today).tokens, for: .beta, today: today)
        }
        let providers: [ProviderID] = gen.coinFlip() ? [.alpha] : [.alpha, .beta]
        let cycleStarts = gen.coinFlip() ? [ProviderID.alpha: gen.localDay(around: today)] : [:]
        let chart = WeekChart.make(history: history, providers: providers, today: today, cycleStarts: cycleStarts)
        #expect(RenderedSize.isDrawn(WeekChartView(chart: chart, descriptors: [.alpha, .beta])), "seed \(seed)")
        #expect(RenderedSize.isDrawn(WeekChartTooltip(chart: chart, day: today, providers: [.alpha, .beta]), width: 160), "seed \(seed)")
    }

    @Test("B-76 the legend's dot renders in each provider's color")
    func legendDotRenders() {
        #expect(RenderedSize.isDrawn(LegendDot(color: Self.accent), width: 6))
    }
}
