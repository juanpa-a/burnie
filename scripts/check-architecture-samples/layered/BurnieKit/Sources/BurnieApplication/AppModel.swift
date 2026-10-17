// expect: none
import BurnieDomain
import BurnieInterface
import Observation

/// What the views see: state, use cases and the clock.
@MainActor
@Observable
public final class AppModel {
    public private(set) var state: AppState
    public let useCases: UseCases
    public let clock: any Clock

    init(state: AppState, useCases: UseCases, clock: any Clock) {
        self.state = state
        self.useCases = useCases
        self.clock = clock
    }
}
