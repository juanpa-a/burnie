// expect: G-11
import CoreServices
import Foundation

public final class DirectoryWatcher: @unchecked Sendable {
    private let queue = DispatchQueue(label: "watcher")
}
