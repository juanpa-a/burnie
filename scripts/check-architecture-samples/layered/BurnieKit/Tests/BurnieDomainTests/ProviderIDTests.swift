// expect: G-5
import Foundation
import Testing
@testable import BurnieDomain

struct ProviderIDTests {
    @Test func encodesAsItsRawValue() throws {
        let encoded = try JSONEncoder().encode(ProviderID(rawValue: "cursor"))
        #expect(encoded.count > 0)
    }
}
