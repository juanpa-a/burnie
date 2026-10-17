// expect: G-6 G-9
import Foundation

/// Stamps a run with the system time, and decodes without handling the error.
struct JobClock {
    let started = Date()

    func decode(_ data: Data) -> Int {
        try! JSONDecoder().decode(Int.self, from: data)
    }
}
