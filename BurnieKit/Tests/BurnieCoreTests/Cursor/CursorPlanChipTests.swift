import Testing
@testable import BurnieCore

struct CursorPlanChipTests {
    @Test(arguments: [
        ("free", "FREE"), ("pro", "PRO"), ("pro_plus", "PRO+"), ("ultra", "ULTRA"),
        ("business", "TEAMS"), ("team", "TEAMS"), ("enterprise", "ENTERPRISE"), ("hobby", "HOBBY"),
    ])
    func labelsMembershipTypes(membership: String, chip: String) {
        #expect(CursorPlanChip.label(membershipType: membership) == chip)
    }

    @Test func hidesTheChipWithoutMembership() {
        #expect(CursorPlanChip.label(membershipType: nil) == nil)
    }
}
