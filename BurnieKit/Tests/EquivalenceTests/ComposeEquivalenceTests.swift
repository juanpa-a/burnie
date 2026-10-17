import BurnieCore
import BurnieDomain
import Foundation
import LegacyTestSupport
import Testing

/// SPEC 16.5: the old `CompositeUsageProvider` and the new `UsageSnapshot.compose` over the full input table. Every
/// sequence of up to 3 refreshes, each of limits or activity with any outcome, compared after every step. Lives only in
/// the intermediate commit that replaces one with the other.
struct ComposeEquivalenceTests {
    /// One refresh: which part, and how it went.
    enum Step: CaseIterable, Sendable {
        case tokenLimits, moneyLimits, limitsOffline, limitsSignInExpired
        case activityWithSpend, activityWithoutSpend, activityNotFound
    }

    /// What either side ends up with: something to show, or the issue of a total failure.
    enum Reading: Equatable {
        case shown(Shown)
        case issue(String)
    }

    /// What either side shows, in plain values both can be turned into.
    struct Shown: Equatable, CustomStringConvertible {
        var fetchedAt: Date
        var plan: String?
        var today: String?
        var meters: [String]
        var issue: String?

        var description: String { "\(fetchedAt.timeIntervalSince1970) \(plan ?? "-") \(today ?? "-") \(meters) \(issue ?? "-")" }
    }

    static let start = Date(timeIntervalSince1970: 1_791_662_400)
    static let timeZone = TimeZone(identifier: "America/Mexico_City")!
    static let day = BurnieCore.LocalDay(start, in: timeZone)

    /// Every sequence of one to three steps.
    static let sequences: [[Step]] = {
        let one = Step.allCases.map { [$0] }
        let two = one.flatMap { first in Step.allCases.map { first + [$0] } }
        let three = two.flatMap { first in Step.allCases.map { first + [$0] } }
        return one + two + three
    }()

    @Test func theTableHasEverySequence() {
        #expect(Self.sequences.count == 7 + 49 + 343)
    }

    @Test("B-7…B-16 the old provider and the new compose show the same after every step", arguments: sequences)
    func oldAndNewShowTheSame(sequence: [Step]) async {
        let clock = ManualClock(now: Self.start, timeZone: Self.timeZone)
        let limits = FakeLimitsSource(.failure(.notFound))
        let activity = FakeActivitySource(.failure(.notFound))
        let old = CompositeUsageProvider(id: .claude, limits: limits, activity: activity, clock: clock)
        var newLimits: BurnieDomain.Latest<BurnieDomain.LimitsPart>?
        var newActivity: BurnieDomain.Latest<BurnieDomain.ActivityPart>?

        #expect(await Self.shown(old, refreshing: []) == Self.shown(newLimits, newActivity))
        for step in sequence {
            clock.advance(by: 60)
            let now = clock.now
            switch Self.outcome(of: step) {
            case .limits(let oldOutcome, let newOutcome):
                limits.set(oldOutcome)
                newLimits = newLimits.map { $0.recording(newOutcome, at: now) } ?? .init(newOutcome, at: now)
                #expect(await Self.shown(old, refreshing: [.limits]) == Self.shown(newLimits, newActivity), "\(sequence)")
            case .activity(let oldOutcome, let newOutcome):
                activity.set(oldOutcome)
                newActivity = newActivity.map { $0.recording(newOutcome, at: now) } ?? .init(newOutcome, at: now)
                #expect(await Self.shown(old, refreshing: [.activity]) == Self.shown(newLimits, newActivity), "\(sequence)")
            }
        }
    }

    // MARK: The two sides

    enum Outcome {
        case limits(Result<BurnieCore.LimitsReading, BurnieCore.ProviderIssue>, Result<BurnieDomain.LimitsPart, BurnieDomain.ProviderIssue>)
        case activity(Result<BurnieCore.ActivityReading, BurnieCore.ProviderIssue>, Result<BurnieDomain.ActivityPart, BurnieDomain.ProviderIssue>)
    }

    static func outcome(of step: Step) -> Outcome {
        let oldMeter = BurnieCore.Meter(id: .session, fraction: 0.64, value: .percent(64), caption: .noActiveSession)
        let newMeter = BurnieDomain.Meter(id: BurnieDomain.MeterID(rawValue: "session"), fill: Fraction(0.64), value: .percent(64), caption: .noActiveSession)
        let newDay = BurnieDomain.LocalDay(start, in: timeZone)
        switch step {
        case .tokenLimits:
            return .limits(
                .success(LimitsReading(plan: "PRO", meters: [oldMeter], unit: .tokens)),
                .success(LimitsPart(plan: PlanName(rawValue: "PRO"), meters: MeterSet(primary: newMeter), unit: .tokens))
            )
        case .moneyLimits:
            return .limits(
                .success(LimitsReading(plan: "TEAMS", meters: [oldMeter], unit: .money)),
                .success(LimitsPart(plan: PlanName(rawValue: "TEAMS"), meters: MeterSet(primary: newMeter), unit: .money))
            )
        case .limitsOffline:
            return .limits(.failure(.offline), .failure(.offline))
        case .limitsSignInExpired:
            return .limits(.failure(.signInExpired), .failure(.signInExpired))
        case .activityWithSpend:
            return .activity(
                .success(ActivityReading(tokens: [day: 1_800_000], spentCents: [day: 1_240])),
                .success(ActivityPart(tokens: [newDay: Tokens(1_800_000)], spent: [newDay: Cents(1_240)]))
            )
        case .activityWithoutSpend:
            return .activity(
                .success(ActivityReading(tokens: [day: 900_000])),
                .success(ActivityPart(tokens: [newDay: Tokens(900_000)]))
            )
        case .activityNotFound:
            return .activity(.failure(.notFound), .failure(.notFound))
        }
    }

    /// What the old provider shows after refreshing `sources`, or the issue it throws.
    static func shown(_ provider: CompositeUsageProvider, refreshing sources: Set<UsageSource>) async -> Reading {
        do {
            let snapshot = try await provider.snapshot(refreshing: sources)
            return .shown(Shown(
                fetchedAt: snapshot.fetchedAt,
                plan: snapshot.plan,
                today: snapshot.today.map { usage in
                    switch usage {
                    case .tokens(let count): "tokens \(count)"
                    case .money(let cents): "money \(cents)"
                    }
                },
                meters: snapshot.meters.map { "\($0.id.rawValue) \($0.fraction)" },
                issue: snapshot.issue.map { "\($0)" }
            ))
        } catch {
            return .issue("\(error)")
        }
    }

    /// What the new compose shows for the latest parts, or its issue.
    static func shown(_ limits: BurnieDomain.Latest<BurnieDomain.LimitsPart>?, _ activity: BurnieDomain.Latest<BurnieDomain.ActivityPart>?) -> Reading {
        let day = BurnieDomain.LocalDay(start, in: timeZone)
        switch BurnieDomain.UsageSnapshot.compose(provider: ProviderID(rawValue: "provider"), limits: limits, activity: activity, today: day, cachedUnit: nil) {
        case .success(let snapshot):
            return .shown(Shown(
                fetchedAt: snapshot.fetchedAt,
                plan: snapshot.plan?.rawValue,
                today: snapshot.today.map { usage in
                    switch usage {
                    case .tokens(let tokens): "tokens \(tokens.count)"
                    case .money(let cents): "money \(cents.amount)"
                    }
                },
                meters: snapshot.meters?.all.map { "\($0.id.rawValue) \($0.fill.value)" } ?? [],
                issue: snapshot.issue.map { "\($0)" }
            ))
        case .failure(let issue):
            return .issue("\(issue)")
        }
    }
}
