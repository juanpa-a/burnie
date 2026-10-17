import BurnieDomain
import BurnieInterface
import Foundation

/// A provider bundle as the reducer keeps it: no closures, which stay with the interpreter.
struct RegisteredProvider: Equatable, Sendable {
    /// Equal by id.
    let descriptor: ProviderDescriptor
    /// The sign-in renewal's failed copy; nil when Burnie can't renew this provider's sign-in.
    let renewalFailedCopy: String?
    let sourceLocation: String?
    let tasks: [RegisteredTask]

    init(_ bundle: ProviderBundle) {
        descriptor = bundle.descriptor
        renewalFailedCopy = bundle.capabilities.signInRenewal?.failedCopy
        sourceLocation = bundle.capabilities.sourceLocation
        tasks = bundle.tasks.map { RegisteredTask(name: $0.name, part: $0.part, policy: $0.policy) }
    }

    var id: ProviderID {
        descriptor.id
    }

    var canRenewSignIn: Bool {
        renewalFailedCopy != nil
    }

    /// The keys of this provider's jobs, one per task.
    var jobKeys: [JobKey] {
        tasks.map { JobKey(provider: id, task: $0.name) }
    }
}
