import BurnieDomain
import BurnieInterface
import Foundation
import Observation

/// What the views read: the app state, the use cases and the clock. The only Application type the views see (A-1).
///
/// It holds the runtime state privately, stamps each event with the clock's `now` and that moment's local day, reduces
/// events one at a time in the order they arrive, publishes the derived `AppState` only when it changes (`@Observable`
/// doesn't compare), and hands each step's effects to the interpreter.
@MainActor @Observable
public final class AppModel {
    public private(set) var state: AppState
    public let useCases: UseCases
    /// For the views' `TimelineView` and deterministic previews (A-6).
    public let clock: any Clock

    @ObservationIgnored private var runtime: RuntimeState
    @ObservationIgnored private let interpreter: Interpreter?
    @ObservationIgnored private var queue: [Event] = []
    @ObservationIgnored private var isReducing = false

    private init(runtime: RuntimeState, clock: any Clock, useCases: UseCases, interpreter: Interpreter?) {
        self.runtime = runtime
        self.clock = clock
        self.useCases = useCases
        self.interpreter = interpreter
        state = .derive(from: runtime)
    }

    /// The app with its runtime: loads what was saved through the synchronous ports, and reduces `launched` before
    /// returning, so the first frame already shows the cache; then the launch effects start.
    public static func live(_ environment: AppEnvironment) -> AppModel {
        let interpreter = Interpreter(environment: environment)
        let registry = environment.providers.map(RegisteredProvider.init)
        let clock = environment.clock
        let model = AppModel(
            runtime: RuntimeState(registry: registry, today: LocalDay(clock.now, in: clock.timeZone)),
            clock: clock,
            useCases: .live(interpreter),
            interpreter: interpreter
        )
        interpreter.deliver = { [weak model] event in model?.send(event) }
        let cache = environment.snapshotCache
        let cached = registry.compactMap { provider in cache.snapshot(for: provider.id).map { (provider.id, $0) } }
        model.send(.launched(
            settings: environment.settingsStore.load(defaultEnabled: Set(registry.map(\.id))),
            cached: Dictionary(uniqueKeysWithValues: cached),
            history: cache.history() ?? UsageHistory()
        ))
        return model
    }

    #if DEBUG
    /// For previews: `state` as given, with use cases that do nothing and no runtime.
    public static func preview(_ state: AppState, clock: any Clock) -> AppModel {
        let model = AppModel(runtime: RuntimeState(registry: [], today: LocalDay(clock.now, in: clock.timeZone)), clock: clock, useCases: .noop, interpreter: nil)
        model.state = state
        return model
    }
    #endif

    /// Stamps `kind` and reduces it once the events before it are done, so an event an effect sends is handled after
    /// the one that caused it (B-37).
    private func send(_ kind: Event.Kind) {
        let now = clock.now
        queue.append(Event(kind: kind, now: now, today: LocalDay(now, in: clock.timeZone)))
        guard !isReducing else { return }
        isReducing = true
        defer { isReducing = false }
        while !queue.isEmpty {
            let (next, effects) = Reducer.reduce(runtime, queue.removeFirst())
            runtime = next
            publish()
            effects.forEach { interpreter?.perform($0) }
        }
    }

    private func publish() {
        let derived = AppState.derive(from: runtime)
        if derived != state {
            state = derived
        }
    }
}
