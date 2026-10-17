// expect: none
import BurnieDomain
import BurnieTestSupport
import Testing
@testable import BurnieProviders

struct ClaudeDescriptorTests {
    @Test func usesTheFrozenID() {
        #expect(ClaudeProvider.descriptor.id == .claude)
        #expect(ClaudeProvider.descriptor.id.rawValue == "claude")
    }
}
