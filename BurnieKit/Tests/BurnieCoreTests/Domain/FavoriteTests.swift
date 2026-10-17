import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct FavoriteTests {
    let both: Set<ProviderID> = [.claude, .cursor]

    // MARK: effective

    @Test("B-52 on first launch there is no favorite")
    func firstLaunchHasNoFavorite() {
        #expect(Favorite.effective(stored: nil, enabled: both) == nil)
    }

    @Test("B-52 the stored favorite stands while it is on")
    func keepsTheStoredFavoriteWhileItIsOn() {
        #expect(Favorite.effective(stored: .cursor, enabled: both) == .cursor)
    }

    @Test("B-52 the only provider on acts as the favorite")
    func theOnlyProviderOnActsAsFavorite() {
        #expect(Favorite.effective(stored: nil, enabled: [.cursor]) == .cursor)
    }

    @Test("B-52 turning the favorite off hands it to the one still on")
    func turningTheFavoriteOffHandsItToTheOneStillOn() {
        #expect(Favorite.effective(stored: .claude, enabled: [.cursor]) == .cursor)
    }

    @Test("B-52 no favorite with every provider off")
    func noFavoriteWhenEverythingIsOff() {
        #expect(Favorite.effective(stored: .claude, enabled: []) == nil)
    }

    // MARK: toggling

    @Test("B-52 marking a favorite replaces the previous one")
    func markingAFavoriteReplacesThePreviousOne() {
        #expect(Favorite.toggling(.cursor, stored: .claude, enabled: both) == .cursor)
    }

    @Test("B-52 tapping the current favorite's heart clears it")
    func tappingTheCurrentFavoriteClearsIt() {
        #expect(Favorite.toggling(.claude, stored: .claude, enabled: both) == nil)
    }

    @Test("B-52 a provider that is off can't be marked")
    func aProviderThatIsOffCantBeMarked() {
        #expect(Favorite.toggling(.cursor, stored: .claude, enabled: [.claude]) == .claude)
    }

    // MARK: ring

    @Test("B-53 the ring follows the favorite's first meter")
    func showsTheFavoritesFirstMeter() {
        let ring = Favorite.ring(stored: .claude, enabled: both, showRing: true, states: [.claude: ready(.claude, fractions: 0.64, 0.38)])
        #expect(ring == .visible(.claude, fraction: 0.64))
    }

    @Test("B-53 no ring without a favorite")
    func hiddenWithoutAFavorite() {
        let ring = Favorite.ring(stored: nil, enabled: both, showRing: true, states: [.claude: ready(.claude, fractions: 0.64)])
        #expect(ring == .hidden)
    }

    @Test("B-53 no ring with the switch off")
    func hiddenWhenTheSwitchIsOff() {
        let ring = Favorite.ring(stored: .claude, enabled: both, showRing: false, states: [.claude: ready(.claude, fractions: 0.64)])
        #expect(ring == .hidden)
    }

    @Test("B-53 the ring follows the provider still on when the favorite is turned off")
    func followsTheProviderStillOnWhenTheFavoriteIsTurnedOff() {
        let states: [ProviderID: ProviderState] = [.claude: ready(.claude, fractions: 0.64), .cursor: ready(.cursor, fractions: 0.35)]
        let ring = Favorite.ring(stored: .claude, enabled: [.cursor], showRing: true, states: states)
        #expect(ring == .visible(.cursor, fraction: 0.35))
    }

    @Test("B-53 no ring until the favorite has a ready snapshot", arguments: [ProviderState.loading, .failed(.notFound)])
    func hiddenUntilTheFavoriteHasData(state: ProviderState) {
        let ring = Favorite.ring(stored: .claude, enabled: both, showRing: true, states: [.claude: state])
        #expect(ring == .hidden)
    }

    @Test("B-53 no ring when the favorite's snapshot has no meters")
    func hiddenWhenTheFavoriteHasNoMeters() {
        let ring = Favorite.ring(stored: .claude, enabled: both, showRing: true, states: [.claude: ready(.claude)])
        #expect(ring == .hidden)
    }

    @Test("B-53 the ring rounds the clamped fill to a whole percent", arguments: [(0.644, 0.64), (0.6451, 0.65), (1.04, 1.0)])
    func roundsTheClampedFractionToAWholePercent(raw: Double, shown: Double) {
        let ring = Favorite.ring(stored: .claude, enabled: both, showRing: true, states: [.claude: ready(.claude, fractions: raw)])
        #expect(ring == .visible(.claude, fraction: shown))
    }

    private func ready(_ provider: ProviderID, fractions: Double...) -> ProviderState {
        let meters = fractions.map { Meter(id: .session, fraction: $0, value: .percent(Int($0 * 100)), caption: .noActiveSession) }
        return .ready(UsageSnapshot(provider: provider, fetchedAt: .iso("2026-10-11T20:00:00Z"), meters: meters))
    }
}
