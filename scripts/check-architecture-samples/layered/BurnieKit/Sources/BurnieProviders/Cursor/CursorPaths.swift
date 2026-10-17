// expect: D-3
import Foundation

/// Finds Cursor's home from the process environment instead of the home it's given.
enum CursorPaths {
    static var home: String { ProcessInfo.processInfo.environment["HOME"] ?? "" }
}
