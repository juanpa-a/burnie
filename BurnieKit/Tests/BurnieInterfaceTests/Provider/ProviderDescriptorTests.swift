import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInterface

struct ProviderDescriptorTests {
    @Test func aMeterReadsItsDeclaredLabel() {
        #expect(ProviderDescriptor.alpha.label(for: .weekly) == "Weekly")
    }

    @Test func anUndeclaredMeterReadsItsIdNeverAnEmptyRow() {
        #expect(ProviderDescriptor.alpha.label(for: MeterID(rawValue: "newMeter")) == "newMeter")
    }

    @Test func descriptorsAreEqualByID() {
        #expect(ProviderDescriptor.alpha == .alpha)
        #expect(ProviderDescriptor.alpha != .beta)
    }
}
