import Foundation

/// Asks a provider's own app to renew its expired sign-in, so Burnie never handles the refresh token itself.
public protocol SignInRenewer: Sendable {
    func renewSignIn() async throws
}
