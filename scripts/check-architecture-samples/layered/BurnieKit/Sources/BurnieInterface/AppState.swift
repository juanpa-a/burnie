// expect: none
import BurnieDomain
import Foundation

/// The value the views render. Its var fields are values, not shared state.
public struct AppState: Equatable, Sendable {
    public var panels: [String]
    public var isRefreshing: Bool

    public static let empty = AppState(panels: [], isRefreshing: false)
}
