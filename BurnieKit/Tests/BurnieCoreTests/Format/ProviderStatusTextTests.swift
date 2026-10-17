import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct ProviderStatusTextTests {
    let now = Date.iso("2026-10-10T20:00:00Z")

    func ready(_ provider: ProviderID, plan: String? = nil, issue: ProviderIssue? = nil) -> ProviderState {
        .ready(UsageSnapshot(provider: provider, fetchedAt: now, plan: plan, issue: issue))
    }

    @Test("B-29 healthy rows show the provider's healthy line")
    func healthyRowsSayWhereTheyRead() {
        #expect(ProviderID.claude.statusText(isEnabled: true, state: ready(.claude), sourceLocation: "~/.config/claude") == "Reading local logs · ~/.config/claude")
        #expect(ProviderID.cursor.statusText(isEnabled: true, state: ready(.cursor, plan: "PRO"), sourceLocation: nil) == "Signed in · Pro plan")
        #expect(ProviderID.cursor.statusText(isEnabled: true, state: ready(.cursor, plan: "PRO+"), sourceLocation: nil) == "Signed in · Pro+ plan")
        #expect(ProviderID.cursor.statusText(isEnabled: true, state: .loading, sourceLocation: nil) == "Signed in")
    }

    @Test("B-29 not found and sign-in expired match the status table")
    func problemsMatchTheStatusTable() {
        #expect(ProviderID.claude.statusText(isEnabled: true, state: .failed(.notFound), sourceLocation: nil) == "Claude Code not found")
        #expect(ProviderID.cursor.statusText(isEnabled: true, state: .failed(.notFound), sourceLocation: nil) == "Cursor not found")
        #expect(ProviderID.claude.statusText(isEnabled: true, state: ready(.claude, issue: .signInExpired), sourceLocation: nil) == "Sign-in expired · open Claude Code")
        #expect(ProviderID.cursor.statusText(isEnabled: true, state: ready(.cursor, issue: .signInExpired), sourceLocation: nil) == "Sign-in expired · open Cursor")
    }

    @Test("B-29 a specific issue, rate limits and offline show the healthy line", arguments: [
        ProviderIssue.missingScope, .rateLimited(retryAt: nil), .offline, .unexpectedResponse("HTTP 404"),
    ])
    func otherIssuesShowTheHealthyLine(issue: ProviderIssue) {
        #expect(ProviderID.claude.statusText(isEnabled: true, state: ready(.claude, issue: issue), sourceLocation: "~/.claude") == "Reading local logs · ~/.claude")
        #expect(ProviderID.claude.statusText(isEnabled: true, state: .failed(issue), sourceLocation: "~/.claude") == "Reading local logs · ~/.claude")
        #expect(ProviderID.cursor.statusText(isEnabled: true, state: ready(.cursor, plan: "PRO", issue: issue), sourceLocation: nil) == "Signed in · Pro plan")
        #expect(ProviderID.cursor.statusText(isEnabled: true, state: .failed(issue), sourceLocation: nil) == "Signed in")
    }

    @Test("B-29 a disabled provider reads Off whatever its state")
    func offWinsOverEverything() {
        #expect(ProviderID.cursor.statusText(isEnabled: false, state: .failed(.notFound), sourceLocation: nil) == "Off")
    }
}
