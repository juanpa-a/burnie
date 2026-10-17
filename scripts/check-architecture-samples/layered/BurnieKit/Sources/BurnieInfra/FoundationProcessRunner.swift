// expect: none
import BurnieInterface
import Foundation

// Serialized by `queue`: every process starts and ends on it.
public final class FoundationProcessRunner: @unchecked Sendable {
    private let queue = DispatchQueue(label: "process")
    // A fixed absolute path, so it always parses.
    private let shell = URL(string: "file:///bin/sh")!
}
