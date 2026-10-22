import BurnieDomain
import Foundation

/// Seeded generator for property tests (SplitMix64). A seed always gives the same values, so the seed a failing
/// expectation prints reproduces the failure (T-8).
public struct Gen: RandomNumberGenerator {
    private static let secondsPerDay = 24 * 60 * 60
    /// How far before or after its anchor `date(around:)` and `localDay(around:)` reach.
    private static let spreadDays = 60
    /// 2026-10-10T20:00:00Z, the moment most tests are at; generated values are around it.
    public static let reference = Date(timeIntervalSince1970: 1_791_662_400)
    /// The local day of `reference` in the zone tests read days in.
    public static let referenceDay = LocalDay(reference, in: .mexicoCity)
    /// The range of `Tokens` and `Cents` the arithmetic laws run over.
    public static let quantities = 0...1_000_000_000_000
    private static let edgeDoubles: [Double] = [.nan, .infinity, -.infinity, .greatestFiniteMagnitude, -.greatestFiniteMagnitude, 0, -0.0, 1]
    private static let meterIDs: [MeterID] = [.daily, .monthly, .budget]
    private static let plans = ["PRO", "MAX", "TEAM"].map(PlanName.init(rawValue:))

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

    // MARK: Primitives

    public mutating func int(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &self)
    }

    /// True or false, half the time each.
    public mutating func coinFlip() -> Bool {
        int(in: 0...1) == 0
    }

    /// Any `Double` an API could send: a quarter of the time NaN, ±∞ or another edge value, otherwise within -1…2,
    /// so a third of those are negative and a third are over 1.
    public mutating func double() -> Double {
        int(in: 0...3) == 0 ? element(of: Self.edgeDoubles) : Double.random(in: -1...2, using: &self)
    }

    /// One of `values`, which must not be empty.
    public mutating func element<Element>(of values: [Element]) -> Element {
        values[int(in: 0...values.count - 1)]
    }

    /// `value` half the time, nil otherwise.
    public mutating func maybe<Value>(_ value: (inout Gen) -> Value) -> Value? {
        coinFlip() ? value(&self) : nil
    }

    // MARK: Time

    /// A moment up to 60 days before or after `date`, to the second.
    public mutating func date(around date: Date = Gen.reference) -> Date {
        let spread = Self.spreadDays * Self.secondsPerDay
        return date.addingTimeInterval(TimeInterval(int(in: -spread...spread)))
    }

    /// A day up to 60 days before or after `day`.
    public mutating func localDay(around day: LocalDay = Gen.referenceDay) -> LocalDay {
        day.advanced(by: int(in: -Self.spreadDays...Self.spreadDays))
    }

    /// `value` stamped at a moment around the reference.
    public mutating func stamped<Value>(_ value: (inout Gen) -> Value) -> Stamped<Value> {
        Stamped(value(&self), at: date())
    }

    // MARK: Domain

    /// One of `ids`, which must not be empty.
    public mutating func providerID(from ids: [ProviderID] = [.alpha, .beta]) -> ProviderID {
        element(of: ids)
    }

    public mutating func tokens() -> Tokens {
        Tokens(int(in: Self.quantities))
    }

    public mutating func cents() -> Cents {
        Cents(int(in: Self.quantities))
    }

    public mutating func issue() -> ProviderIssue {
        switch int(in: 0...5) {
        case 0: .notFound
        case 1: .signInExpired
        case 2: .rateLimited(retryAt: maybe { $0.date() })
        case 3: .offline
        case 4: .unexpectedResponse("HTTP \(int(in: 400...599))")
        default: .specific(SpecificIssue(code: element(of: ["missingScope", "otherCode"])))
        }
    }

    /// A meter of any kind whose fill came from `double()`, so the clamp has run on it.
    public mutating func meter() -> Meter {
        Meter(
            id: element(of: Self.meterIDs),
            fill: Fraction(double()),
            value: meterValue(),
            caption: caption(),
            scope: coinFlip() ? .own : .team,
            period: maybe { $0.period() }
        )
    }

    /// One to four meters.
    public mutating func meterSet() -> MeterSet {
        MeterSet(primary: meter(), others: (0..<int(in: 0...3)).map { _ in meter() })
    }

    public mutating func features() -> SnapshotFeatures {
        SnapshotFeatures(onDemand: maybe { $0.meter() })
    }

    public mutating func unit() -> UsageUnit {
        coinFlip() ? .tokens : .money
    }

    public mutating func limitsPart() -> LimitsPart {
        LimitsPart(plan: maybe { $0.element(of: Self.plans) }, meters: meterSet(), unit: unit(), features: features())
    }

    /// Tokens for up to ten days around `today`, and spend for some of them.
    public mutating func activityPart(around today: LocalDay = Gen.referenceDay) -> ActivityPart {
        var part = ActivityPart(tokens: [:])
        for _ in 0..<int(in: 0...10) {
            let day = localDay(around: today)
            part.tokens[day] = tokens()
            if coinFlip() {
                part.spent[day] = cents()
            }
        }
        return part
    }

    public mutating func todayUsage() -> TodayUsage {
        coinFlip() ? .tokens(tokens()) : .money(cents())
    }

    /// A success or a failure of `value`, with or without an earlier success.
    public mutating func latest<Value>(_ value: (inout Gen) -> Value) -> Latest<Value> {
        coinFlip()
            ? .success(stamped(value))
            : .failure(issue(), at: date(), lastSuccess: maybe { $0.stamped(value) })
    }

    /// A snapshot of either content, with or without a partial issue.
    public mutating func snapshot() -> UsageSnapshot {
        let content: SnapshotContent = coinFlip()
            ? .limits(view: stamped { $0.limitsPart() }, today: maybe { $0.todayUsage() })
            : .activityOnly(stamped { $0.todayUsage() })
        return UsageSnapshot(provider: providerID(), content: content, issue: maybe { $0.issue() })
    }

    // MARK: Pieces

    private mutating func meterValue() -> MeterValue {
        coinFlip() ? .percent(int(in: 0...100)) : .money(used: cents(), limit: maybe { $0.cents() })
    }

    private mutating func caption() -> MeterCaption {
        switch int(in: 0...4) {
        case 0: .resetsIn(date())
        case 1: .resetsAt(date())
        case 2: .cycleEnds(date())
        case 3: .noActiveSession
        default: .onDemandIdle
        }
    }

    /// A window of up to 30 days.
    private mutating func period() -> DateInterval {
        DateInterval(start: date(), duration: TimeInterval(int(in: 1...30 * Self.secondsPerDay)))
    }
}
