import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct FavoriteTests {
    let both: Set<ProviderID> = [.claude, .cursor]

    // MARK: effective

    @Test func firstLaunchHasNoFavorite() {
        #expect(Favorite.effective(stored: nil, enabled: both) == nil)
    }

    @Test func keepsTheStoredFavoriteWhileItIsOn() {
        #expect(Favorite.effective(stored: .cursor, enabled: both) == .cursor)
    }

    @Test func theOnlyProviderOnActsAsFavorite() {
        #expect(Favorite.effective(stored: nil, enabled: [.cursor]) == .cursor)
    }

    @Test func turningTheFavoriteOffHandsItToTheOneStillOn() {
        #expect(Favorite.effective(stored: .claude, enabled: [.cursor]) == .cursor)
    }

    @Test func noFavoriteWhenEverythingIsOff() {
        #expect(Favorite.effective(stored: .claude, enabled: []) == nil)
    }

    // MARK: toggling

    @Test func markingAFavoriteReplacesThePreviousOne() {
        #expect(Favorite.toggling(.cursor, stored: .claude, enabled: both) == .cursor)
    }

    @Test func tappingTheCurrentFavoriteClearsIt() {
        #expect(Favorite.toggling(.claude, stored: .claude, enabled: both) == nil)
    }

    @Test func aProviderThatIsOffCantBeMarked() {
        #expect(Favorite.toggling(.cursor, stored: .claude, enabled: [.claude]) == .claude)
    }

    // MARK: ring

    @Test func showsTheFavoritesFirstMeter() {
        let ring = Favorite.ring(stored: .claude, enabled: both, showRing: true, states: [.claude: ready(.claude, fractions: 0.64, 0.38)])
        #expect(ring == .visible(.claude, fraction: 0.64))
    }

    @Test func hiddenWithoutAFavorite() {
        let ring = Favorite.ring(stored: nil, enabled: both, showRing: true, states: [.claude: ready(.claude, fractions: 0.64)])
        #expect(ring == .hidden)
    }

    @Test func hiddenWhenTheSwitchIsOff() {
        let ring = Favorite.ring(stored: .claude, enabled: both, showRing: false, states: [.claude: ready(.claude, fractions: 0.64)])
        #expect(ring == .hidden)
    }

    @Test func followsTheProviderStillOnWhenTheFavoriteIsTurnedOff() {
        let states: [ProviderID: ProviderState] = [.claude: ready(.claude, fractions: 0.64), .cursor: ready(.cursor, fractions: 0.35)]
        let ring = Favorite.ring(stored: .claude, enabled: [.cursor], showRing: true, states: states)
        #expect(ring == .visible(.cursor, fraction: 0.35))
    }

    @Test(arguments: [ProviderState.loading, .failed(.notFound)])
    func hiddenUntilTheFavoriteHasData(state: ProviderState) {
        let ring = Favorite.ring(stored: .claude, enabled: both, showRing: true, states: [.claude: state])
        #expect(ring == .hidden)
    }

    @Test func hiddenWhenTheFavoriteHasNoMeters() {
        let ring = Favorite.ring(stored: .claude, enabled: both, showRing: true, states: [.claude: ready(.claude)])
        #expect(ring == .hidden)
    }

    @Test(arguments: [(0.644, 0.64), (0.6451, 0.65), (1.04, 1.0)])
    func roundsTheClampedFractionToAWholePercent(raw: Double, shown: Double) {
        let ring = Favorite.ring(stored: .claude, enabled: both, showRing: true, states: [.claude: ready(.claude, fractions: raw)])
        #expect(ring == .visible(.claude, fraction: shown))
    }

    private func ready(_ provider: ProviderID, fractions: Double...) -> ProviderState {
        let meters = fractions.map { Meter(id: .session, fraction: $0, value: .percent(Int($0 * 100)), caption: .noActiveSession) }
        return .ready(UsageSnapshot(provider: provider, fetchedAt: .iso("2026-10-11T20:00:00Z"), meters: meters))
    }
}
