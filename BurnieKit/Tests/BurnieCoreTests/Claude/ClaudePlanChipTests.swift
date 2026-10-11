import Testing
@testable import BurnieCore

struct ClaudePlanChipTests {
    @Test(arguments: [
        ("claude_max", "MAX"), ("max", "MAX"),
        ("claude_pro", "PRO"), ("pro", "PRO"),
        ("team", "TEAM"), ("claude_enterprise", "ENTERPRISE"),
    ])
    func labelsPlansFromTheProfileOrTheCredentials(plan: String, chip: String) {
        #expect(ClaudePlanChip.label(plan: plan) == chip)
    }

    @Test func hidesTheChipForUnknownPlans() {
        #expect(ClaudePlanChip.label(plan: "free") == nil)
        #expect(ClaudePlanChip.label(plan: nil) == nil)
    }
}
