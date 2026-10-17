import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct FavoriteTests {
    let both: Set<ProviderID> = [.alpha, .beta]

    /// A ready state with one meter per fill, in display order; without fills, today's usage alone.
    func ready(_ provider: ProviderID, fills: Double...) -> ProviderState {
        let at = Date.iso("2026-10-11T20:00:00Z")
        let meters = fills.map { Meter(id: .daily, fill: Fraction($0), value: .percent(Int($0 * 100)), caption: .noActiveSession) }
        guard let meterSet = MeterSet(meters) else {
            return .ready(UsageSnapshot(provider: provider, content: .activityOnly(Stamped(.tokens(.zero), at: at))))
        }
        return .ready(UsageSnapshot(provider: provider, content: .limits(view: Stamped(LimitsPart(plan: nil, meters: meterSet), at: at), today: nil)))
    }

    // MARK: effective

    @Test("B-52 on first launch there is no favorite")
    func firstLaunchHasNoFavorite() {
        #expect(Favorite.effective(stored: nil, enabled: both) == nil)
    }

    @Test("B-52 the stored favorite stands while it is on")
    func keepsTheStoredFavoriteWhileItIsOn() {
        #expect(Favorite.effective(stored: .beta, enabled: both) == .beta)
    }

    @Test("B-52 the only provider on acts as the favorite")
    func theOnlyProviderOnActsAsFavorite() {
        #expect(Favorite.effective(stored: nil, enabled: [.beta]) == .beta)
    }

    @Test("B-52 turning the favorite off hands it to the one still on")
    func turningTheFavoriteOffHandsItToTheOneStillOn() {
        #expect(Favorite.effective(stored: .alpha, enabled: [.beta]) == .beta)
    }

    @Test("B-52 no favorite with every provider off")
    func noFavoriteWhenEverythingIsOff() {
        #expect(Favorite.effective(stored: .alpha, enabled: []) == nil)
    }

    @Test("B-52 an unknown stored favorite reads as none")
    func anUnknownStoredFavoriteReadsAsNone() {
        #expect(Favorite.effective(stored: ProviderID(rawValue: "gone"), enabled: both) == nil)
    }

    // MARK: toggling

    @Test("B-52 marking a favorite replaces the previous one")
    func markingAFavoriteReplacesThePreviousOne() {
        #expect(Favorite.toggling(.beta, stored: .alpha, enabled: both) == .beta)
    }

    @Test("B-52 tapping the current favorite's heart clears it")
    func tappingTheCurrentFavoriteClearsIt() {
        #expect(Favorite.toggling(.alpha, stored: .alpha, enabled: both) == nil)
    }

    @Test("B-52 a provider that is off can't be marked")
    func aProviderThatIsOffCantBeMarked() {
        #expect(Favorite.toggling(.beta, stored: .alpha, enabled: [.alpha]) == .alpha)
    }

    @Test(arguments: Gen.seeds(200))
    func tappingTwiceGivesBackTheStoredFavoriteOrClearsAnother(seed: UInt64) {
        var gen = Gen(seed: seed)
        let enabled = Set([ProviderID.alpha, .beta].filter { _ in gen.coinFlip() })
        let stored = gen.maybe { $0.providerID() }
        let id = gen.providerID()
        let twice = Favorite.toggling(id, stored: Favorite.toggling(id, stored: stored, enabled: enabled), enabled: enabled)
        let expected = !enabled.contains(id) || stored == nil || stored == id ? stored : nil
        #expect(twice == expected, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func theEffectiveFavoriteIsEnabledOrNone(seed: UInt64) {
        var gen = Gen(seed: seed)
        let enabled = Set([ProviderID.alpha, .beta].filter { _ in gen.coinFlip() })
        let effective = Favorite.effective(stored: gen.maybe { $0.providerID() }, enabled: enabled)
        #expect(effective.map(enabled.contains) ?? true, "seed \(seed)")
    }

    // MARK: ring

    @Test("B-53 the ring follows the favorite's primary meter")
    func showsTheFavoritesPrimaryMeter() {
        let ring = Favorite.ring(stored: .alpha, enabled: both, showRing: true, states: [.alpha: ready(.alpha, fills: 0.64, 0.38)])
        #expect(ring == .visible(.alpha, percent: 64))
    }

    @Test("B-53 no ring without a favorite")
    func hiddenWithoutAFavorite() {
        let ring = Favorite.ring(stored: nil, enabled: both, showRing: true, states: [.alpha: ready(.alpha, fills: 0.64)])
        #expect(ring == .hidden)
    }

    @Test("B-53 no ring with the switch off")
    func hiddenWhenTheSwitchIsOff() {
        let ring = Favorite.ring(stored: .alpha, enabled: both, showRing: false, states: [.alpha: ready(.alpha, fills: 0.64)])
        #expect(ring == .hidden)
    }

    @Test("B-53 the ring follows the provider still on when the favorite is turned off")
    func followsTheProviderStillOnWhenTheFavoriteIsTurnedOff() {
        let states = [ProviderID.alpha: ready(.alpha, fills: 0.64), .beta: ready(.beta, fills: 0.35)]
        let ring = Favorite.ring(stored: .alpha, enabled: [.beta], showRing: true, states: states)
        #expect(ring == .visible(.beta, percent: 35))
    }

    @Test("B-53 no ring until the favorite has a ready snapshot", arguments: [ProviderState.loading, .failed(.notFound)])
    func hiddenUntilTheFavoriteHasData(state: ProviderState) {
        let ring = Favorite.ring(stored: .alpha, enabled: both, showRing: true, states: [.alpha: state])
        #expect(ring == .hidden)
    }

    @Test("B-53 no ring when the favorite's snapshot has no meters")
    func hiddenWhenTheFavoriteHasNoMeters() {
        let ring = Favorite.ring(stored: .alpha, enabled: both, showRing: true, states: [.alpha: ready(.alpha)])
        #expect(ring == .hidden)
    }

    @Test("B-53 the ring rounds the clamped fill to a whole percent", arguments: [(0.644, 64), (0.6451, 65), (1.04, 100)])
    func roundsTheClampedFillToAWholePercent(raw: Double, percent: Int) {
        let ring = Favorite.ring(stored: .alpha, enabled: both, showRing: true, states: [.alpha: ready(.alpha, fills: raw)])
        #expect(ring == .visible(.alpha, percent: percent))
    }

    @Test(arguments: Gen.seeds(200))
    func theRingIsThePrimaryFillAsAWholePercent(seed: UInt64) {
        var gen = Gen(seed: seed)
        let view = gen.stamped { $0.limitsPart() }
        let snapshot = UsageSnapshot(provider: .alpha, content: .limits(view: view, today: nil))
        let ring = Favorite.ring(stored: .alpha, enabled: both, showRing: true, states: [.alpha: .ready(snapshot)])
        let percent = Int((view.value.meters.primary.fill.value * 100).rounded())
        #expect(ring == .visible(.alpha, percent: percent), "seed \(seed)")
        #expect((0...100).contains(percent), "seed \(seed)")
    }
}
