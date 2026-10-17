import BurnieInterface
import Foundation
import os

/// `DiagnosticsLog` over the unified log, under Burnie's subsystem and the category it was built for (a provider's id,
/// or the app's). Its records are compile-time names and numbers, so every part is public (B-64).
public struct OSDiagnosticsLog: DiagnosticsLog {
    static let subsystem = "dev.juanpa.burnie"
    /// The same digits on every Mac, whatever its locale.
    private static let secondsFormat = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(2)).locale(Locale(identifier: "en_US_POSIX"))

    private let logger: Logger

    public init(category: String) {
        logger = Logger(subsystem: Self.subsystem, category: category)
    }

    public func record(_ event: StaticString, _ measures: [Measure]) {
        let message = Self.message(event, measures)
        logger.info("\(message, privacy: .public)")
    }

    /// "http status 200, elapsed 0.42 s"
    static func message(_ event: StaticString, _ measures: [Measure]) -> String {
        let parts = measures.map { measure in
            switch measure {
            case .count(let name, let count): "\(name) \(count)"
            case .bytes(let name, let bytes): "\(name) \(bytes) bytes"
            case .seconds(let name, let seconds): "\(name) \(seconds.formatted(Self.secondsFormat)) s"
            case .status(let status): "status \(status)"
            }
        }
        return "\(event) " + parts.joined(separator: ", ")
    }
}
