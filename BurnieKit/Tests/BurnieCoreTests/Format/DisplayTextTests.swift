import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct DisplayTextTests {
    @Test func issueRowsMatchTheErrorsTable() {
        #expect(ProviderIssue.notFound.message(for: .claude) == "Claude Code not found. Install it and sign in.")
        #expect(ProviderIssue.signInExpired.message(for: .claude) == "Limits paused. Open Claude Code to refresh sign-in.")
        #expect(ProviderIssue.missingScope.message(for: .claude) == "This sign-in can't read limits. Run `claude` and log in again.")
        #expect(ProviderIssue.notFound.message(for: .cursor) == "Cursor not found. Sign in to the Cursor app.")
        #expect(ProviderIssue.signInExpired.message(for: .cursor) == "Session expired. Open Cursor to sign in again.")
        #expect(ProviderIssue.unexpectedResponse("HTTP 404").message(for: .cursor) == "Couldn't read usage. Burnie may need an update.")
    }

    @Test func renewingAnExpiredSignInPointsToTheProvidersOwnLogin() {
        #expect(ProviderIssue.renewSignInTitle == "Refresh sign-in")
        #expect(ProviderIssue.renewalFailedMessage(for: .claude) == "Couldn't refresh sign-in. Run `claude` in Terminal and log in again.")
        #expect(ProviderIssue.renewalFailedMessage(for: .cursor) == "Couldn't refresh sign-in. Open Cursor to sign in again.")
    }

    @Test func rateLimitsAndOfflineShowNoRow() {
        #expect(ProviderIssue.rateLimited(retryAt: nil).message(for: .claude) == nil)
        #expect(ProviderIssue.offline.message(for: .cursor) == nil)
    }

    @Test func daysAreLabeledInTheLocale() {
        let saturday = LocalDay.day("2026-10-10")
        #expect(DayLabelFormatter(locale: .enUS).letter(for: saturday) == "S")
        #expect(DayLabelFormatter(locale: .enUS).shortName(for: saturday) == "Sat")
        #expect(DayLabelFormatter(locale: Locale(identifier: "es_MX")).letter(for: saturday) == "S")
        #expect(DayLabelFormatter(locale: .enUS).letter(for: .day("2026-10-14")) == "W")
    }

    @Test func snapshotsGoStaleAfterThirtyMinutes() {
        let snapshot = UsageSnapshot(provider: .claude, fetchedAt: .iso("2026-10-10T20:00:00Z"))
        #expect(!snapshot.isStale(at: .iso("2026-10-10T20:30:00Z")))
        #expect(snapshot.isStale(at: .iso("2026-10-10T20:30:01Z")))
    }
}
