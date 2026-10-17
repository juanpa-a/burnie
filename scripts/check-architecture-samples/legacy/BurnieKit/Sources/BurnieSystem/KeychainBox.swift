// expect: none
import Foundation

/// Caches the last secret read.
// Serialized by `lock`: every read and write of `secret` holds it.
public final class KeychainBox: @unchecked Sendable {
    private let lock = NSLock()
    private var secret: String?
}
