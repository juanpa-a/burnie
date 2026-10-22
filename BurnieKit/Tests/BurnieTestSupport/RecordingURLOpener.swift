import BurnieInterface
import Foundation

/// A `URLOpener` that remembers what it opened.
@MainActor
public final class RecordingURLOpener: URLOpener {
    public private(set) var opened: [URL] = []

    public init() {}

    public func open(_ url: URL) {
        opened.append(url)
    }
}
