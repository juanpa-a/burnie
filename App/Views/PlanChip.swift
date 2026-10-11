import SwiftUI

/// "MAX", "PRO": the provider's plan next to its name.
struct PlanChip: View {
    let plan: String

    var body: some View {
        Text(plan)
            .font(Tokens.Typography.chip)
            .tracking(0.3)
            .foregroundStyle(Tokens.Palette.fg2)
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background(RoundedRectangle(cornerRadius: 4).fill(Tokens.Palette.chip))
    }
}
