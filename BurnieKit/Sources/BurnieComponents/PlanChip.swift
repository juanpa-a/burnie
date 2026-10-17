import BurnieDomain
import SwiftUI

/// "MAX", "PRO": the provider's plan next to its name.
public struct PlanChip: View {
    let plan: PlanName

    public init(plan: PlanName) {
        self.plan = plan
    }

    public var body: some View {
        Text(plan.rawValue)
            .font(DesignTokens.Typography.chip)
            .tracking(DesignTokens.Typography.chipTracking)
            .foregroundStyle(DesignTokens.Palette.fg2)
            .padding(.vertical, DesignTokens.Insets.chipVertical)
            .padding(.horizontal, DesignTokens.Insets.chipHorizontal)
            .background(RoundedRectangle(cornerRadius: DesignTokens.Metrics.chipRadius).fill(DesignTokens.Palette.chip))
    }
}

#Preview {
    PreviewFrame {
        PlanChip(plan: PreviewValues.plan)
    }
}
