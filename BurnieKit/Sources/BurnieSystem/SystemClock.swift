import Foundation
import BurnieCore

public struct SystemClock: Clock {
    public init() {}

    public var now: Date { Date() }
    public var timeZone: TimeZone { .current }
}
