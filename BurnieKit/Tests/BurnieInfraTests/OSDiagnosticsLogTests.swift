import Foundation
import Testing
@testable import BurnieInfra

struct OSDiagnosticsLogTests {
    @Test("B-64 a record reads as its event and its numbers")
    func recordReadsAsEventAndNumbers() {
        let message = OSDiagnosticsLog.message("logScan", [.count("filesRead", 3), .bytes("bytesRead", 4_096), .seconds("elapsed", 0.4213), .status(200)])
        #expect(message == "logScan filesRead 3, bytesRead 4096 bytes, elapsed 0.42 s, status 200")
    }
}
