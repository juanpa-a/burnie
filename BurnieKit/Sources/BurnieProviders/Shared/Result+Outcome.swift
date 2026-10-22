import BurnieDomain
import Foundation

extension Result where Failure == ProviderIssue {
    /// What a refresh task returns: the part `body` reads, or the issue it threw. A task never throws (SPEC 5.3).
    static func outcome(of body: () async throws(ProviderIssue) -> Success) async -> Result {
        do {
            return .success(try await body())
        } catch {
            return .failure(error)
        }
    }
}
