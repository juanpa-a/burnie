import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct CircuitBreakerTests {
    static let unexpected: Result<Int, ProviderIssue> = .failure(.unexpectedResponse("HTTP 403"))
    static let otherOutcomes: [Result<Int, ProviderIssue>] = [
        .success(1), .failure(.notFound), .failure(.signInExpired), .failure(.specific(.alphaScope)),
        .failure(.rateLimited(retryAt: nil)), .failure(.offline),
    ]

    @Test("B-81 three unexpected issues in a row trip the breaker, and more keep it tripped")
    func threeUnexpectedInARowTrip() {
        var breaker = CircuitBreaker()
        var tripped: [Bool] = []
        for _ in 0..<5 {
            breaker.record(Self.unexpected)
            tripped.append(breaker.isTripped)
        }
        #expect(tripped == [false, false, true, true, true])
    }

    @Test("B-81 any other outcome resets the breaker, tripped or not", arguments: otherOutcomes)
    func otherOutcomesReset(outcome: Result<Int, ProviderIssue>) {
        var breaker = CircuitBreaker()
        for _ in 0..<3 {
            breaker.record(Self.unexpected)
        }
        breaker.record(outcome)
        #expect(breaker == CircuitBreaker())
        breaker.record(Self.unexpected)
        breaker.record(Self.unexpected)
        #expect(!breaker.isTripped)
    }

    @Test(arguments: Gen.seeds(200))
    func trippedExactlyAfterThreeUnexpectedInARow(seed: UInt64) {
        var gen = Gen(seed: seed)
        var breaker = CircuitBreaker()
        var unexpectedInARow = 0
        for _ in 0..<gen.int(in: 1...12) {
            let outcome = gen.coinFlip() ? Self.unexpected : gen.element(of: Self.otherOutcomes)
            breaker.record(outcome)
            unexpectedInARow = if case .failure(.unexpectedResponse) = outcome { unexpectedInARow + 1 } else { 0 }
            #expect(breaker.isTripped == (unexpectedInARow >= 3), "seed \(seed)")
            if unexpectedInARow == 0 {
                #expect(breaker == CircuitBreaker(), "seed \(seed)")
            }
        }
    }
}
