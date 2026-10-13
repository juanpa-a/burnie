import BurnieCore
import SwiftUI

/// An expired sign-in's issue row, with a button that asks the provider's own app to renew it.
struct SignInRenewalRow: View {
    let message: String
    let failedMessage: String
    /// Returns false if the provider's app couldn't renew the sign-in.
    let renew: () async -> Bool

    @State private var isRenewing = false
    @State private var hasFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            IssueRow(message: hasFailed ? failedMessage : message)
            ChipButton(title: ProviderIssue.renewSignInTitle, isBusy: isRenewing) {
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
