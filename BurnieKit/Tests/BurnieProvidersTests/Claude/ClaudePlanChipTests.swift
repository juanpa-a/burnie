import BurnieDomain
import Foundation
import Testing
@testable import BurnieProviders

struct ClaudePlanChipTests {
    @Test("B-9 Claude plan chips, with or without the claude_ prefix", arguments: [
        ("claude_max", "MAX"), ("max", "MAX"),
        ("claude_pro", "PRO"), ("pro", "PRO"),
        ("team", "TEAM"), ("claude_enterprise", "ENTERPRISE"),
    ])
    func labelsPlansFromTheProfileOrTheCredentials(plan: String, chip: String) {
        #expect(ClaudePlanChip.label(plan: plan)?.rawValue == chip)
    }

    @Test("B-9 an unknown Claude plan shows no chip")
    func hidesTheChipForUnknownPlans() {
        #expect(ClaudePlanChip.label(plan: "free") == nil)
        #expect(ClaudePlanChip.label(plan: nil) == nil)
    }
}
