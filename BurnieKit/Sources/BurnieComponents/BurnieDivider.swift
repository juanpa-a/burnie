import SwiftUI

/// A 1 pt line between regions, inset horizontally.
public struct BurnieDivider: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(DesignTokens.Palette.line)
            .frame(height: DesignTokens.Metrics.dividerThickness)
            .padding(.horizontal, DesignTokens.Metrics.dividerInset)
    }
}

#if DEBUG
#Preview {
    PreviewFrame {
        BurnieDivider()
    }
}
#endif
