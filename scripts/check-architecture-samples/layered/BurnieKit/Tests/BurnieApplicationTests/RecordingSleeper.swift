// expect: G-11
import BurnieInterface
import Foundation

final class RecordingSleeper: Sleeper, @unchecked Sendable {
    var waits: [Duration] = []
}
