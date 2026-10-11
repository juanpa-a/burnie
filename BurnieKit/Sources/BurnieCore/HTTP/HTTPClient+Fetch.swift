import Foundation

extension HTTPClient {
    /// A GET that turns any failure into a `ProviderIssue` using the rules shared by every provider:
    /// no network or timeout → `.offline`, 429 → `.rateLimited`, 5xx → `.offline`.
    ///
    /// `classify` applies the provider's own rules (expired session, HTML instead of JSON…)
    /// before any other non-2xx response ends up as `.unexpectedResponse`.
    func fetch(
        _ url: URL,
        headers: [String: String],
        now: Date,
        classify: (HTTPURLResponse, Data) -> ProviderIssue?
    ) async throws(ProviderIssue) -> Data {
        let (body, response) = try await send(url, headers: headers)
        switch response.statusCode {
        case 429: throw .rateLimited(retryAt: RetryAfter.date(from: response.value(forHTTPHeaderField: "Retry-After"), now: now))
        case 500...: throw .offline
        default: break
        }
        if let issue = classify(response, body) { throw issue }
        guard (200..<300).contains(response.statusCode) else { throw .unexpectedResponse("HTTP \(response.statusCode)") }
        return body
    }

    private func send(_ url: URL, headers: [String: String]) async throws(ProviderIssue) -> (Data, HTTPURLResponse) {
        do {
            return try await get(url, headers: headers)
        } catch is URLError {
            throw .offline
        } catch {
            throw .unexpectedResponse(String(describing: error))
        }
    }
}
