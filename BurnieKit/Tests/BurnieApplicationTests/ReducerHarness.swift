import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieApplication

/// Reduces events one after another, stamped at a moment the test moves, and checks after each one the invariant of
/// SPEC 7.3: every job has a run in flight or an armed timer, except a job that needs the network while offline.
struct ReducerHarness {
    static let start = Date.iso("2026-10-10T20:00:00Z")

    var state: RuntimeState
    var now = Self.start
    var timeZone = TimeZone.mexicoCity
    private var nextRequest = 0

    init(providers: TestProviders = TestProviders()) {
        state = RuntimeState(registry: providers.bundles.map(RegisteredProvider.init), today: LocalDay(Self.start, in: .mexicoCity))
    }

    /// After a first launch with nothing saved, and each job's first run finished with its fake's outcome.
    static func launched(
        settings: AppSettings? = nil,
        cached: [ProviderID: UsageSnapshot] = [:],
        history: UsageHistory = UsageHistory(),
        finishing outcomes: [JobKey: Result<Part, ProviderIssue>] = ReducerHarness.healthyOutcomes
    ) -> ReducerHarness {
        var harness = ReducerHarness()
        let effects = harness.send(.launched(settings: settings ?? .defaults(enabled: [.alpha, .beta]), cached: cached, history: history))
        for (key, run) in effects.runs {
            if let outcome = outcomes[key] {
                harness.send(.taskFinished(key, run, outcome, jitter: 0))
            }
        }
        return harness
    }

    static let healthyOutcomes: [JobKey: Result<Part, ProviderIssue>] = [
        TestProviders.alphaLimitsJob: .success(.limits(TestProviders.alphaLimits)),
        TestProviders.alphaActivityJob: .success(.activity(TestProviders.activity)),
        TestProviders.betaLimitsJob: .success(.limits(TestProviders.betaLimits)),
        TestProviders.betaActivityJob: .success(.activity(TestProviders.activity)),
    ]

    @discardableResult
    mutating func send(_ kind: Event.Kind, sourceLocation: SourceLocation = #_sourceLocation) -> [Effect] {
        let (next, effects) = Reducer.reduce(state, Event(kind: kind, now: now, today: LocalDay(now, in: timeZone)))
        state = next
        checkInvariant(sourceLocation: sourceLocation)
        return effects
    }

    mutating func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }

    /// A request id the test hasn't used yet, as the interpreter would draw it.
    mutating func newRequest() -> RequestID {
        defer { nextRequest += 1 }
        return RequestID(value: nextRequest)
    }

    /// Finishes every run in `effects` with its fake's healthy outcome.
    mutating func finishAll(_ effects: [Effect], jitter: Double = 0) -> [Effect] {
        effects.runs.flatMap { key, run in send(.taskFinished(key, run, Self.healthyOutcomes[key] ?? .failure(.notFound), jitter: jitter)) }
    }

    /// The armed timer of `key`, as the interpreter would fire it.
    func timer(of key: JobKey) -> TimerID? {
        state.jobs[key]?.timer
    }

    func shown(_ id: ProviderID) -> UsageSnapshot? {
        state.shown[id]?.snapshot
    }

    private func checkInvariant(sourceLocation: SourceLocation) {
        for (key, job) in state.jobs where job.running == nil && job.timer == nil {
            let waitsForTheNetwork = job.policy.needsNetwork && !state.isOnline
            #expect(waitsForTheNetwork, "\(key.provider.rawValue).\(key.task) has neither a run nor a timer", sourceLocation: sourceLocation)
        }
    }
}

extension Array where Element == Effect {
    /// The runs these effects ask for, in order.
    var runs: [(JobKey, RunID)] {
        compactMap { effect in
            guard case .runTask(let key, let run) = effect else { return nil }
            return (key, run)
        }
    }

    /// The jobs these effects ask to run, in order.
    var ranJobs: [JobKey] {
        runs.map(\.0)
    }

    /// The delays of the timers these effects arm, by job.
    var timerDelays: [JobKey: TimeInterval] {
        reduce(into: [:]) { delays, effect in
            if case .scheduleTimer(let key, _, let delay) = effect {
                delays[key] = delay
            }
        }
    }
}
