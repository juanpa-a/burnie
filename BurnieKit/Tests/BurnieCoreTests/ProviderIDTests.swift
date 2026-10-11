import Testing
@testable import BurnieCore

struct ProviderIDTests {
    @Test func rendersClaudeBeforeCursor() {
        #expect(ProviderID.allCases == [.claude, .cursor])
    }
}
