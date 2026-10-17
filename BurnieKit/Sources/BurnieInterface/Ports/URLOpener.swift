import Foundation

/// Opens an external URL in the user's browser.
@MainActor
public protocol URLOpener {
    func open(_ url: URL)
}
