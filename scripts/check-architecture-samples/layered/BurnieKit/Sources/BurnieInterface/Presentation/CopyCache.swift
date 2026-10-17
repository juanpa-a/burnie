// expect: I-2
import Foundation

/// Copy kept in a class.
public final class CopyCache: Sendable {
    public let entries: [String: String] = [:]
}
