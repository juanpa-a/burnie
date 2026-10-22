import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInterface

struct StatusLineTests {
    @Test("B-29 healthy rows show the provider's healthy line")
    func healthyRowsShowTheProvidersLine() {
        #expect(StatusLine.text(for: PanelSamples.panel(.alpha, state: PanelSamples.ready(.alpha), sourceLocation: "~/.config/alpha")) == "Reading local logs · ~/.config/alpha")
        #expect(StatusLine.text(for: PanelSamples.panel(.beta, state: PanelSamples.ready(.beta, plan: "PRO+"))) == "Signed in · Pro+ plan")
        #expect(StatusLine.text(for: PanelSamples.panel(.beta, state: .loading)) == "Signed in")
    }

    @Test("B-29 not found and sign-in expired read the common templates over the display name")
    func notFoundAndSignInExpiredUseTheTemplates() {
        #expect(StatusLine.text(for: PanelSamples.panel(.alpha, state: .failed(.notFound))) == "Alpha Code not found")
        #expect(StatusLine.text(for: PanelSamples.panel(.beta, state: PanelSamples.ready(.beta, issue: .signInExpired))) == "Sign-in expired · open Beta")
    }

    @Test("B-29 a specific issue, rate limits, offline and an unexpected answer show the healthy line", arguments: [
        ProviderIssue.specific(.alphaScope), .rateLimited(retryAt: nil), .offline, .unexpectedResponse("HTTP 404"),
    ])
    func otherIssuesShowTheHealthyLine(issue: ProviderIssue) {
        let healthy = "Reading local logs · ~/.alpha"
        #expect(StatusLine.text(for: PanelSamples.panel(.alpha, state: PanelSamples.ready(.alpha, issue: issue))) == healthy)
        #expect(StatusLine.text(for: PanelSamples.panel(.alpha, state: .failed(issue))) == healthy)
    }

    @Test("B-29 a disabled provider reads Off whatever its state")
    func offWinsOverEverything() {
        #expect(StatusLine.text(for: PanelSamples.panel(.beta, isEnabled: false, state: .failed(.notFound))) == "Off")
    }
}
