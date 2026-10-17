// expect: G-3
import Foundation
import os

/// Sends scan reports to the unified log, which BurnieCore can't reach: it imports only Foundation.
public struct DiagnosticsSink: Sendable {
    let logger = Logger(subsystem: "dev.example.burnie", category: "scan")
}
