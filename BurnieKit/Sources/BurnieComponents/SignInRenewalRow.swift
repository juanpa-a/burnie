import BurnieInterface
import SwiftUI

/// An expired sign-in's issue row, with a button that asks the provider's own app to renew it. When it couldn't, the
/// row says how to sign in by hand (B-22).
public struct SignInRenewalRow: View {
    let message: String
    let failedMessage: String
    /// Returns false if the provider's app couldn't renew the sign-in.
    let renew: () async -> Bool

    @State private var isRenewing = false
    @State private var hasFailed = false

    public init(message: String, failedMessage: String, renew: @escaping () async -> Bool) {
        self.message = message
        self.failedMessage = failedMessage
        self.renew = renew
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.related) {
            IssueRow(message: hasFailed ? failedMessage : message)
            ChipButton(title: Copy.renewSignIn, isBusy: isRenewing) {
                Task { await renewSignIn() }
            }
        }
    }

    private func renewSignIn() async {
        isRenewing = true
        let didRenew = await renew()
        hasFailed = !didRenew
        isRenewing = false
    }
}

#Preview {
    PreviewFrame {
        SignInRenewalRow(message: PreviewValues.issue, failedMessage: PreviewValues.failedRenewal) { false }
    }
}
