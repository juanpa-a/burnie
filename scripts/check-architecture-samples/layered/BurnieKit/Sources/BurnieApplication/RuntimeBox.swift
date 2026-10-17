// expect: G-11
import Foundation

// Serialized by `lock`, but outside Infra a comment doesn't make it allowed.
final class RuntimeBox: @unchecked Sendable {
    private let lock = NSLock()
}
