// expect: G-7
import Foundation

/// Writes a scan report to standard output.
public enum ScanReportPrinter {
    public static func show(files: Int, seconds: Double) {
        print("scanned \(files) files in \(seconds) s")
    }
}
