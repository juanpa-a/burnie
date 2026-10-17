import Foundation

/// What a provider can do, fixed when it's assembled; each capability is optional, and the UI asks with `if let`.
public struct ProviderCapabilities: Sendable {
    /// nil: Burnie can't renew this provider's sign-in.
    public var signInRenewal: SignInRenewal?
    /// Where the provider reads from (`"~/.claude"`), shown in its status line; nil when it reads no local files.
    public var sourceLocation: String?

    public init(signInRenewal: SignInRenewal? = nil, sourceLocation: String? = nil) {
        self.signInRenewal = signInRenewal
        self.sourceLocation = sourceLocation
    }
}
