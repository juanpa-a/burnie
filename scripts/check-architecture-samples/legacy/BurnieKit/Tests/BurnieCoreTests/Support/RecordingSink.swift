// expect: G-11
import Foundation

final class RecordingSink: @unchecked Sendable {
    var reports: [String] = []
}
