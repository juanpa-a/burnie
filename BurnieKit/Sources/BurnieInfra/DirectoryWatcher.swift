import BurnieInterface
import CoreServices
import Foundation

/// FSEvents over the directories it was built for that exist when it starts, with a 2 s latency to coalesce bursts
/// (B-72). A directory created later is picked up the next time it starts.
// `queue` serializes `stream` and `onChange`, and receives the events.
public final class DirectoryWatcher: ActivityWatcher, @unchecked Sendable {
    private let directories: [URL]
    private let latency: TimeInterval
    private let queue = DispatchQueue(label: "dev.juanpa.burnie.directory-watcher")
    private var stream: FSEventStreamRef?
    private var onChange: (@Sendable () -> Void)?

    public init(directories: [URL], latency: TimeInterval = 2) {
        self.directories = directories
        self.latency = latency
    }

    deinit {
        stop()
    }

    public func start(onChange: @escaping @Sendable () -> Void) {
        queue.sync {
            guard stream == nil else { return }
            let existing = directories.map { $0.path(percentEncoded: false) }.filter { FileManager.default.fileExists(atPath: $0) }
            guard !existing.isEmpty else { return }
            self.onChange = onChange

            var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
            let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
                guard let info else { return }
                Unmanaged<DirectoryWatcher>.fromOpaque(info).takeUnretainedValue().onChange?()
            }
            guard let stream = FSEventStreamCreate(
                nil, callback, &context, existing as CFArray,
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
