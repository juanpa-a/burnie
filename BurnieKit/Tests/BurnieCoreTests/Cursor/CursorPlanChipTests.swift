import Testing
@testable import BurnieCore

struct CursorPlanChipTests {
    @Test("B-9 Cursor plan chips from the membership type, uppercased when unknown", arguments: [
        ("free", "FREE"), ("pro", "PRO"), ("pro_plus", "PRO+"), ("ultra", "ULTRA"),
        ("business", "TEAMS"), ("team", "TEAMS"), ("enterprise", "ENTERPRISE"), ("hobby", "HOBBY"),
    ])
    func labelsMembershipTypes(membership: String, chip: String) {
        #expect(CursorPlanChip.label(membershipType: membership) == chip)
    }

    @Test("B-9 without a membership type Cursor shows no chip")
    func hidesTheChipWithoutMembership() {
        #expect(CursorPlanChip.label(membershipType: nil) == nil)
    }
}
