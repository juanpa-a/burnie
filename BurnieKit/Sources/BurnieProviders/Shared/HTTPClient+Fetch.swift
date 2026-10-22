import BurnieDomain
import BurnieInterface
import Foundation

extension HTTPClient {
    /// Sends `request` and turns any failure into a `ProviderIssue` with the rules every provider shares (B-24): no
    /// response → offline, 429 → rate limited until its `Retry-After`, 5xx → offline.
    ///
    /// `classify` applies the provider's own rules (an expired session, HTML instead of data…) before any other
    /// non-2xx response reads as unexpected.
    func fetch(_ request: HTTPRequest, now: Date, classify: (HTTPResponse) -> ProviderIssue?) async throws(ProviderIssue) -> Data {
        let response = try await response(to: request)
        switch response.status {
        case 429: throw .rateLimited(retryAt: RetryAfter.date(from: response.header("Retry-After"), now: now))
        case 500...: throw .offline
        default: break
        }
        if let issue = classify(response) { throw issue }
        guard (200..<300).contains(response.status) else { throw .unexpectedResponse("HTTP \(response.status)") }
        return response.body
    }

    private func response(to request: HTTPRequest) async throws(ProviderIssue) -> HTTPResponse {
        do throws(HTTPFailure) {
            return try await send(request)
        } catch {
            switch error {
            case .offline: throw .offline
            case .other(let description): throw .unexpectedResponse(description)
            }
        }
    }
}
