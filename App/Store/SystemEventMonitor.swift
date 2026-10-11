import AppKit
import Network

/// Reports when the Mac wakes up and when the network comes and goes.
@MainActor
final class SystemEventMonitor {
    private let pathMonitor = NWPathMonitor()
    private var wakeObserver: NSObjectProtocol?

    func start(onWake: @escaping @Sendable () -> Void, onNetworkChange: @escaping @Sendable (_ isOnline: Bool) -> Void) {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: nil
        ) { _ in onWake() }
        pathMonitor.pathUpdateHandler = { path in onNetworkChange(path.status == .satisfied) }
        pathMonitor.start(queue: DispatchQueue(label: "dev.juanpa.burnie.network"))
    }
}
