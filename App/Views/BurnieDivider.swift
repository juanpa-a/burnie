import SwiftUI

/// A 1 pt line between regions, inset horizontally.
struct BurnieDivider: View {
    var body: some View {
        Rectangle()
            .fill(Tokens.Palette.line)
            .frame(height: 1)
            .padding(.horizontal, Tokens.Metrics.dividerInset)
    }
}
