// expect: none
import Foundation
import Testing

/// AppTests is test code: force unwraps and try! need no comment, and a fake may be @unchecked Sendable with one.
struct SettingRecorderTests {
    /// `lock` serializes `saves`, so tasks can share it.
    final class Recorder: @unchecked Sendable {
        private let lock = NSLock()
        private var saves: [Bool] = []
    }

    @Test func readsBackWhatItSaved() {
        let saved = try! JSONDecoder().decode([Bool].self, from: "[true]".data(using: .utf8)!)
        #expect(saved == [true])
    }
}
