// expect: D-2
import Foundation

/// History kept in an actor instead of as a value.
public actor HistoryStore {
    private var days: [LocalDay: Int] = [:]
}
