import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
@testable import BurnieApplication

/// Two invented providers shaped like the real ones: `alpha` paces like Claude (limits 5 min ± 30 s, a watched activity
/// that needs no network) and can renew its sign-in; `beta` paces like Cursor (limits 10 min ± 30 s, activity 30 min,
/// both over the network) and can't.
final class TestProviders: Sendable {
    static let today = LocalDay.day("2026-10-10")
    static let alphaMeters = MeterSet(primary: Meter(id: .daily, fill: Fraction(0.64), value: .percent(64), caption: .noActiveSession))
    static let betaMeters = MeterSet(primary: Meter(id: .budget, fill: Fraction(0.37), value: .money(used: Cents(18_420), limit: Cents(50_000)), caption: .noActiveSession))
    static let onDemand = Meter(id: .extra, fill: .zero, value: .money(used: .zero, limit: Cents(2_000)), caption: .onDemandIdle)
    static let alphaLimits = LimitsPart(plan: PlanName(rawValue: "MAX"), meters: alphaMeters)
    static let betaLimits = LimitsPart(plan: PlanName(rawValue: "PRO"), meters: betaMeters, unit: .money, features: SnapshotFeatures(onDemand: onDemand))
    static let activity = ActivityPart(tokens: [today: Tokens(1_800_000), .day("2026-10-08"): Tokens(400_000)])

    static let alphaLimitsPolicy = RefreshPolicy(interval: 300, jitter: 30, staleOnOpen: 60, needsNetwork: true)
    static let alphaActivityPolicy = RefreshPolicy(interval: 300, jitter: 0, staleOnOpen: nil, needsNetwork: false)
    static let betaLimitsPolicy = RefreshPolicy(interval: 600, jitter: 30, staleOnOpen: 60, needsNetwork: true)
    static let betaActivityPolicy = RefreshPolicy(interval: 1_800, jitter: 0, staleOnOpen: 600, needsNetwork: true)

    static let alphaLimitsJob = JobKey(provider: .alpha, task: "limits")
    static let alphaActivityJob = JobKey(provider: .alpha, task: "activity")
    static let betaLimitsJob = JobKey(provider: .beta, task: "limits")
    static let betaActivityJob = JobKey(provider: .beta, task: "activity")

    let alphaLimits = FakeRefreshTask(.success(.limits(TestProviders.alphaLimits)))
    let alphaActivity = FakeRefreshTask(.success(.activity(TestProviders.activity)))
    let betaLimits = FakeRefreshTask(.success(.limits(TestProviders.betaLimits)))
    let betaActivity = FakeRefreshTask(.success(.activity(TestProviders.activity)))
    let watcher = FakeActivityWatcher()
    let renewer = FakeProcessRunner()

    /// Both, in registry order.
    var bundles: [ProviderBundle] {
        [alpha, beta]
    }

    var alpha: ProviderBundle {
        let runner = renewer
        return ProviderBundle(
            descriptor: .alpha,
            capabilities: ProviderCapabilities(
                signInRenewal: SignInRenewal(failedCopy: "Alpha couldn't renew.") { await runner.run(URL(filePath: "/alpha"), arguments: []) == 0 },
                sourceLocation: "~/.alpha"
            ),
            tasks: [
                alphaLimits.task(named: "limits", part: .limits, policy: Self.alphaLimitsPolicy),
                alphaActivity.task(named: "activity", part: .activity, policy: Self.alphaActivityPolicy, watcher: watcher),
            ]
        )
    }

    var beta: ProviderBundle {
        ProviderBundle(
            descriptor: .beta,
            capabilities: ProviderCapabilities(),
            tasks: [
                betaLimits.task(named: "limits", part: .limits, policy: Self.betaLimitsPolicy),
                betaActivity.task(named: "activity", part: .activity, policy: Self.betaActivityPolicy),
            ]
        )
    }

    /// How many times each of `alpha`'s tasks ran: limits, then activity.
    var alphaRuns: [Int] {
        [alphaLimits.calls, alphaActivity.calls]
    }

    var betaRuns: [Int] {
        [betaLimits.calls, betaActivity.calls]
    }
}
