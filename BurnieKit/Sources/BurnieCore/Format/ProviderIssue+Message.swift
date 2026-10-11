import Foundation

extension ProviderIssue {
    /// The text of a section's issue row; nil when no row is shown.
    /// On 429 or offline the cached data is shown and the header already reveals its age.
    public func message(for provider: ProviderID) -> String? {
        switch (self, provider) {
        case (.rateLimited, _), (.offline, _): nil
        case (.notFound, .claude): "Claude Code not found. Install it and sign in."
        case (.notFound, .cursor): "Cursor not found. Sign in to the Cursor app."
        case (.signInExpired, .claude): "Limits paused. Open Claude Code to refresh sign-in."
        case (.signInExpired, .cursor): "Session expired. Open Cursor to sign in again."
        case (.missingScope, .claude): "This sign-in can't read limits. Run `claude` and log in again."
        case (.missingScope, .cursor), (.unexpectedResponse, _): "Couldn't read usage. Burnie may need an update."
        }
    }
}
