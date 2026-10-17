import BurnieDomain
import Foundation

extension RuntimeState {
    /// Asks the provider's app to renew its sign-in, keeping the request open while it runs; a provider that's off or
    /// can't renew answers false at once (B-22).
    mutating func renewSignIn(of id: ProviderID, for request: RequestID) -> [Effect] {
        guard settings.enabled.contains(id), provider(id)?.canRenewSignIn == true else {
            return [.finishRequest(request, result: false)]
        }
        open(request, isRenewing: true)
        return [.renewSignIn(id, request)]
    }

    /// A renewal that worked refreshes the provider's limits as part of the same request (B-23, B-59).
    mutating func finishRenewal(of id: ProviderID, succeeded: Bool, for request: RequestID, now: Date) -> [Effect] {
        requests[request]?.isRenewing = false
        requests[request]?.result = succeeded
        let refresh = succeeded ? startRuns(of: enabledJobKeys(of: id, yielding: .limits), for: .manual, request: request, now: now) : []
        return refresh + closeIfDone(request)
    }
}
