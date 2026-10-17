// expect: none
import BurnieInterface

extension AppModel {
    /// Builds the running app model.
    public static func live(_ environment: AppEnvironment) -> AppModel {
        AppModel(state: .empty, useCases: UseCases(environment), clock: environment.clock)
    }
}
