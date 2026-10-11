import Foundation
@testable import BurnieCore

struct FakeSecretReader: SecretReader {
    var items: [String: Data] = [:]

    func genericPassword(service: String, account: String?) throws -> Data? {
        items[service]
    }
}
