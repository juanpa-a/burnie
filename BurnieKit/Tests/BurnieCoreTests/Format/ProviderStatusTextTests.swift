import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct ProviderStatusTextTests {
    let now = Date.iso("2026-10-10T20:00:00Z")

    func ready(_ provider: ProviderID, plan: String? = nil, issue: ProviderIssue? = nil) -> ProviderState {
        .ready(UsageSnapshot(provider: provider, fetchedAt: now, plan: plan, issue: issue))
    }

    @Test func healthyRowsSayWhereTheyRead() {
        #expect(ProviderID.claude.statusText(isEnabled: true, state: ready(.claude), sourceLocation: "~/.config/claude") == "Reading local logs · ~/.config/claude")
        #expect(ProviderID.cursor.statusText(isEnabled: true, state: ready(.cursor, plan: "PRO"), sourceLocation: nil) == "Signed in · Pro plan")
        #expect(ProviderID.cursor.statusText(isEnabled: true, state: ready(.cursor, plan: "PRO+"), sourceLocation: nil) == "Signed in · Pro+ plan")
        #expect(ProviderID.cursor.statusText(isEnabled: true, state: .loading, sourceLocation: nil) == "Signed in")
    }

    @Test func problemsMatchTheStatusTable() {
        #expect(ProviderID.claude.statusText(isEnabled: true, state: .failed(.notFound), sourceLocation: nil) == "Claude Code not found")
        #expect(ProviderID.cursor.statusText(isEnabled: true, state: .failed(.notFound), sourceLocation: nil) == "Cursor not found")
        #expect(ProviderID.claude.statusText(isEnabled: true, state: ready(.claude, issue: .signInExpired), sourceLocation: nil) == "Sign-in expired · open Claude Code")
        #expect(ProviderID.cursor.statusText(isEnabled: true, state: ready(.cursor, issue: .signInExpired), sourceLocation: nil) == "Sign-in expired · open Cursor")
    }

    @Test func offWinsOverEverything() {
        #expect(ProviderID.cursor.statusText(isEnabled: false, state: .failed(.notFound), sourceLocation: nil) == "Off")
    }
}
