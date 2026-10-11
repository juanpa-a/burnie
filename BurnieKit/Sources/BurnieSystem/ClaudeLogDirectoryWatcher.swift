import CoreServices
import Foundation
import BurnieCore

/// FSEvents over the Claude log folders that exist, with 2 s latency to coalesce bursts.
public final class ClaudeLogDirectoryWatcher: ActivityWatcher, @unchecked Sendable {
    private let roots: [URL]
    private let latency: TimeInterval
    /// Serializes all mutable state and receives the events.
    private let queue = DispatchQueue(label: "dev.juanpa.burnie.claude-log-watcher")
    private var stream: FSEventStreamRef?
    private var onChange: (@Sendable () -> Void)?

    public init(roots: [URL], latency: TimeInterval = 2) {
        self.roots = roots
        self.latency = latency
    }

    deinit {
        stop()
    }

    public func start(onChange: @escaping @Sendable () -> Void) {
        queue.sync {
            guard stream == nil else { return }
            let existingRoots = roots.map { $0.path(percentEncoded: false) }.filter { FileManager.default.fileExists(atPath: $0) }
            guard !existingRoots.isEmpty else { return }
            self.onChange = onChange

            var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
            let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
                guard let info else { return }
                Unmanaged<ClaudeLogDirectoryWatcher>.fromOpaque(info).takeUnretainedValue().onChange?()
            }
            guard let stream = FSEventStreamCreate(
                nil, callback, &context, existingRoots as CFArray,
                FSEventStreamEventId(kFSEventStreamEventIdSinceNow), latency,
                FSEventStreamCreateFlags(kFSEventStreamCreateFlagNone)
            ) else { return }
            FSEventStreamSetDispatchQueue(stream, queue)
            FSEventStreamStart(stream)
            self.stream = stream
        }
    }

    public func stop() {
        queue.sync {
            guard let stream else { return }
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
            onChange = nil
        }
    }
}
