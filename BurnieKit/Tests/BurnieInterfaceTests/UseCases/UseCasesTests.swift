import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInterface

struct UseCasesTests {
    @MainActor
    @Test func theNoOpRenewalReportsThatItCouldNot() async {
        #expect(await UseCases.noop.renewSignIn(.alpha) == false)
    }

    @MainActor
    @Test func aUseCaseCallsItsAction() {
        var tapped: [ProviderID] = []
        let toggle = ToggleFavorite { tapped.append($0) }
        toggle(.beta)
        #expect(tapped == [.beta])
    }
}
