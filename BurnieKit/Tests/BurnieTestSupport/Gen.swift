import BurnieCore
import Foundation

/// Seeded generator for property tests (SplitMix64). A seed always gives the same values, so the seed a failing
/// expectation prints reproduces the failure.
public struct Gen: RandomNumberGenerator {
    private static let secondsPerDay = 24 * 60 * 60
    /// How far before or after its anchor `date(around:)` and `localDay(around:)` reach.
    private static let spreadDays = 60
    /// 2026-10-10T20:00:00Z, the moment most tests are at; generated meters and snapshots are around it.
    private static let reference = Date(timeIntervalSince1970: 1_791_662_400)
    private static let edgeDoubles: [Double] = [.nan, .infinity, -.infinity, .greatestFiniteMagnitude, -.greatestFiniteMagnitude, 0, -0.0, 1]
    private static let meterIDs: [MeterID] = [.session, .weekly, .cursorModels, .otherModels, .included, .onDemand]
    private static let plans = ["PRO", "MAX", "TEAM"]

    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    /// The seeds a property test runs over: `@Test(arguments: Gen.seeds(200))`.
    public static func seeds(_ count: Int) -> [UInt64] {
        (0..<count).map { UInt64($0) }
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }

    public mutating func int(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &self)
    }

    /// Any `Double` an API could send: a quarter of the time NaN, ±∞ or another edge value, otherwise within -1…2,
    /// so a third of those are negative and a third are over 1.
    public mutating func double() -> Double {
        int(in: 0...3) == 0 ? element(of: Self.edgeDoubles) : Double.random(in: -1...2, using: &self)
    }

    /// A moment up to 60 days before or after `date`, to the second.
    public mutating func date(around date: Date) -> Date {
        let spread = Self.spreadDays * Self.secondsPerDay
        return date.addingTimeInterval(TimeInterval(int(in: -spread...spread)))
    }

    /// A day up to 60 days before or after `day`.
    public mutating func localDay(around day: LocalDay) -> LocalDay {
        day.advanced(by: int(in: -Self.spreadDays...Self.spreadDays))
    }

    /// One of `ids`, which must not be empty.
    public mutating func providerID(from ids: [ProviderID]) -> ProviderID {
        element(of: ids)
    }

    public mutating func issue() -> ProviderIssue {
        switch int(in: 0...5) {
        case 0: .notFound
        case 1: .signInExpired
        case 2: .missingScope
        case 3: .rateLimited(retryAt: coinFlip() ? date(around: Self.reference) : nil)
        case 4: .offline
        default: .unexpectedResponse("HTTP \(int(in: 400...599))")
        }
    }

    /// A meter of any kind whose fraction came from `double()`, so the clamp has run on it.
    public mutating func meter() -> Meter {
        Meter(
            id: element(of: Self.meterIDs),
            fraction: double(),
            value: meterValue(),
            caption: caption(),
            period: coinFlip() ? period() : nil
        )
    }

    /// A snapshot of any provider; half of them have no meters, as when only the activity arrived.
    public mutating func snapshot() -> UsageSnapshot {
        UsageSnapshot(
            provider: providerID(from: ProviderID.allCases),
            fetchedAt: date(around: Self.reference),
            plan: coinFlip() ? element(of: Self.plans) : nil,
            today: coinFlip() ? todayUsage() : nil,
            meters: coinFlip() ? (0..<int(in: 1...3)).map { _ in meter() } : [],
            issue: coinFlip() ? issue() : nil
        )
    }

    private mutating func coinFlip() -> Bool {
        int(in: 0...1) == 0
    }

    private mutating func element<Element>(of values: [Element]) -> Element {
        values[int(in: 0...values.count - 1)]
    }

    private mutating func meterValue() -> MeterValue {
        coinFlip()
            ? .percent(int(in: 0...100))
            : .money(usedCents: int(in: 0...100_000), limitCents: coinFlip() ? int(in: 0...100_000) : nil)
    }

    private mutating func caption() -> MeterCaption {
        switch int(in: 0...4) {
        case 0: .resetsIn(date(around: Self.reference))
        case 1: .resetsAt(date(around: Self.reference))
        case 2: .cycleEnds(date(around: Self.reference))
        case 3: .noActiveSession
        default: .onDemandIdle
        }
    }

    /// A window of up to 30 days.
    private mutating func period() -> DateInterval {
        DateInterval(start: date(around: Self.reference), duration: TimeInterval(int(in: 1...30 * Self.secondsPerDay)))
    }

    private mutating func todayUsage() -> TodayUsage {
        coinFlip() ? .tokens(int(in: 0...100_000_000)) : .money(cents: int(in: 0...100_000))
    }
}
