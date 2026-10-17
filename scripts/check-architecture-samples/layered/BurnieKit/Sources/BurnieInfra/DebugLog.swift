// expect: G-7
import Foundation

/// Prints instead of logging.
struct DebugLog {
    func record(_ event: String) {
        debugPrint(event)
    }
}
