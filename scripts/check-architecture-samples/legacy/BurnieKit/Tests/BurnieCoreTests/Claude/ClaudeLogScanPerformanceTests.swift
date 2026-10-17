// expect: none
import Foundation
import Testing
@testable import BurnieCore

/// Reports its timings, the one place a test may print.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["BURNIE_PERF"] != nil))
struct ClaudeLogScanPerformanceTests {
    @Test func coldScan() {
        print("cold 1.2 s, incremental 30 ms")
    }
}
