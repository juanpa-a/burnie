import Foundation

extension ProviderIssue {
    /// The button under an expired sign-in that the provider's own app can renew.
    public static let renewSignInTitle = "Refresh sign-in"

    /// Takes the place of the expired sign-in's message once the provider's app tried and couldn't renew it.
    public static func renewalFailedMessage(for provider: ProviderID) -> String {
        switch provider {
        case .claude: "Couldn't refresh sign-in. Run `claude` in Terminal and log in again."
        case .cursor: "Couldn't refresh sign-in. Open Cursor to sign in again."
        }
    }
}
