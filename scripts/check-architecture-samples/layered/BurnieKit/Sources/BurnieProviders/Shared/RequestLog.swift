// expect: P-1
import Foundation

/// Logs requests on its own instead of through DiagnosticsLog.
struct RequestLog {
    let logger = Logger(subsystem: "dev.example.burnie", category: "http")
}
