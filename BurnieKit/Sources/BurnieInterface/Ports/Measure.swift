import Foundation

/// One number in a diagnostics record, always public in the log.
public enum Measure: Sendable {
    case count(StaticString, Int)
    case bytes(StaticString, Int)
    case seconds(StaticString, Double)
    case status(Int)
}
