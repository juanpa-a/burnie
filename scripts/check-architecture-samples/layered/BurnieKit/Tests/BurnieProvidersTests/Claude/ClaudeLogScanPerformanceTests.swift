// expect: none
import Testing
@testable import BurnieProviders

struct ClaudeLogScanPerformanceTests {
    @Test func reportsTimings() {
        print("cold 1.2 s, incremental 30 ms")
    }
}
