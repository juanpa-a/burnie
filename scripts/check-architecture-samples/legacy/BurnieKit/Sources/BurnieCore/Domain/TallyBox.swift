// expect: G-11
import Foundation

// Guarded by `lock`, but only Infra and test fakes may opt out of checked sendability.
public final class TallyBox: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    public func increment() {
        lock.withLock { count += 1 }
    }
}
