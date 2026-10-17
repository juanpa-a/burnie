import Foundation

/// `{"offline": {}}`, `{"rateLimited": {"retryAt": 1760000000}}`, `{"unexpectedResponse": "HTTP 500"}` or
/// `{"specific": "missingScope"}` (SPEC section 12).
extension ProviderIssue: Codable {
    private enum Case: String, CodingKey {
        case notFound, signInExpired, rateLimited, offline, unexpectedResponse, specific
    }

    private enum RateLimitedKey: String, CodingKey {
        case retryAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Case.self)
        switch try container.onlyCase() {
        case .notFound:
            self = .notFound
        case .signInExpired:
            self = .signInExpired
        case .rateLimited:
            let rateLimited = try container.nestedContainer(keyedBy: RateLimitedKey.self, forKey: .rateLimited)
            self = .rateLimited(retryAt: try rateLimited.decodeIfPresent(Date.self, forKey: .retryAt))
        case .offline:
            self = .offline
        case .unexpectedResponse:
            self = .unexpectedResponse(try container.decode(String.self, forKey: .unexpectedResponse))
        case .specific:
            self = .specific(try container.decode(SpecificIssue.self, forKey: .specific))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Case.self)
        switch self {
        case .notFound:
            container.encodeEmptyCase(.notFound)
        case .signInExpired:
            container.encodeEmptyCase(.signInExpired)
        case .rateLimited(let retryAt):
            var rateLimited = container.nestedContainer(keyedBy: RateLimitedKey.self, forKey: .rateLimited)
            try rateLimited.encodeIfPresent(retryAt, forKey: .retryAt)
        case .offline:
            container.encodeEmptyCase(.offline)
        case .unexpectedResponse(let detail):
            try container.encode(detail, forKey: .unexpectedResponse)
        case .specific(let issue):
            try container.encode(issue, forKey: .specific)
        }
    }
}
