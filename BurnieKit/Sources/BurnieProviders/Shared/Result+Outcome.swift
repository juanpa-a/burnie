import BurnieDomain
import Foundation

extension Result where Failure == ProviderIssue {
    /// What `body` returns, or the issue it threw: how a refresh task answers, since a task never throws (SPEC 5.3).
    static func outcome(of body: () async throws(ProviderIssue) -> Success) async -> Result {
        do {
            return .success(try await body())
        } catch {
            return .failure(error)
        }
    }
}
