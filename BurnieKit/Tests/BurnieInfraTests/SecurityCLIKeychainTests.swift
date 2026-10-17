import Foundation
import Testing
@testable import BurnieInfra

struct SecurityCLIKeychainTests {
    @Test func missingItemIsNil() throws {
        let service = "dev.juanpa.burnie.tests.\(UUID().uuidString)"
        #expect(try SecurityCLIKeychain().genericPassword(service: service, account: NSUserName()) == nil)
    }
}
