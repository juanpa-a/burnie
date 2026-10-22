import AppKit
import BurnieInterface
import Network

/// `SystemEvents` over `NSWorkspace`'s wake notification and `NWPathMonitor`.
@MainActor
public final class MacSystemEvents: SystemEvents {
    private let pathMonitor = NWPathMonitor()
    private var wakeObserver: NSObjectProtocol?

    public init() {}

    public func start(onWake: @escaping @Sendable () -> Void, onNetworkChange: @escaping @Sendable (_ isOnline: Bool) -> Void) {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: nil
        ) { _ in onWake() }
        pathMonitor.pathUpdateHandler = { path in onNetworkChange(path.status == .satisfied) }
        pathMonitor.start(queue: DispatchQueue(label: "dev.juanpa.burnie.network"))
    }
}
