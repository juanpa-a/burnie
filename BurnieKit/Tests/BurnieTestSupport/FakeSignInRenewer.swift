import BurnieCore
import Foundation

/// A `SignInRenewer` whose outcome the test sets; its `gate` holds a renewal while the test keeps it closed, as the
/// provider's app would while it renews.
/// `lock` serializes `succeeds` and `callCount`, so tasks can share it.
public final class FakeSignInRenewer: SignInRenewer, @unchecked Sendable {
    /// What a failing renewal throws, as the provider's app exiting with an error would.
    public struct Failure: Error {}

    public let gate = Gate()
    private let lock = NSLock()
    private var succeeds: Bool
    private var callCount = 0

    /// How many renewals went past the gate.
    public var calls: Int { lock.withLock { callCount } }

    public init(succeeds: Bool = true) {
        self.succeeds = succeeds
    }

    public func set(succeeds: Bool) {
        lock.withLock { self.succeeds = succeeds }
    }

    public func renewSignIn() async throws {
        await gate.pass()
        let succeeds = lock.withLock {
            callCount += 1
            return self.succeeds
        }
        guard succeeds else { throw Failure() }
    }
}
