// expect: G-7
import Testing

/// AppTests is scanned: a print in the app's tests fails like anywhere else.
struct UsageStoreLogTests {
    @Test func printsWhatItRefreshed() {
        print("refreshed")
        #expect(Bool(true))
    }
}
