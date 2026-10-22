import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInterface

struct IssueMessageTests {
    @Test("B-20 rate limits and offline show no issue row", arguments: [ProviderIssue.rateLimited(retryAt: nil), .offline])
    func rateLimitsAndOfflineShowNoRow(issue: ProviderIssue) {
        #expect(IssueMessage.message(for: issue, copy: ProviderDescriptor.alpha.copy) == nil)
    }

    @Test("B-21 not found and an expired sign-in read the provider's copy")
    func commonIssuesReadTheProvidersCopy() {
        #expect(IssueMessage.message(for: .notFound, copy: ProviderDescriptor.alpha.copy) == "Alpha Code not found.")
        #expect(IssueMessage.message(for: .signInExpired, copy: ProviderDescriptor.beta.copy) == "Beta session expired.")
    }

    @Test("B-21 a specific issue reads the copy its provider declares")
    func specificIssueReadsItsCopy() {
        #expect(IssueMessage.message(for: .specific(.alphaScope), copy: ProviderDescriptor.alpha.copy) == "Alpha can't read limits.")
    }

    @Test("B-21 an unexpected response, or a specific issue without copy, reads the same for every provider", arguments: [
        ProviderDescriptor.alpha, .beta,
    ])
    func unexpectedIssuesShareTheirCopy(descriptor: ProviderDescriptor) {
        let unexpected = "Couldn't read usage. Burnie may need an update."
        #expect(IssueMessage.message(for: .unexpectedResponse("HTTP 404"), copy: descriptor.copy) == unexpected)
        #expect(IssueMessage.message(for: .specific(SpecificIssue(code: "unknown")), copy: descriptor.copy) == unexpected)
    }
}
