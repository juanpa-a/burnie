import AppKit
import BurnieInterface

/// `URLOpener` over `NSWorkspace`: the user's default browser.
@MainActor
public struct WorkspaceURLOpener: URLOpener {
    public init() {}

    public func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}
