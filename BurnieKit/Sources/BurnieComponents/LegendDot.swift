import BurnieInterface
import SwiftUI

/// A provider's color as a small dot, before its name in the week chart's legend and tooltip.
struct LegendDot: View {
    let color: ColorPair
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Circle()
            .fill(DesignTokens.Palette.accent(color, in: colorScheme))
            .frame(width: DesignTokens.Metrics.legendDot, height: DesignTokens.Metrics.legendDot)
    }
}

#if DEBUG
#Preview {
    PreviewFrame {
        LegendDot(color: PreviewValues.northwind.color)
    }
}
#endif
