import Foundation
import Testing
@testable import BurnieInfra

struct SecurityFrameworkKeychainTests {
    @Test func missingItemIsNil() throws {
        let service = "dev.juanpa.burnie.tests.\(UUID().uuidString)"
        #expect(try SecurityFrameworkKeychain().genericPassword(service: service, account: NSUserName()) == nil)
    }
}
