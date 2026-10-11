import SwiftUI

/// A 28×28 button with an SF Symbol, like the ones in the header.
struct IconButton: View {
    let systemName: String
    let accessibilityLabel: String
    var weight: Font.Weight = .medium
    var color = Tokens.Palette.fg2
    /// Turns 360° per second while true (Refresh in progress) and always finishes the turn it's on,
    /// so a quick refresh still shows one full turn and the symbol never snaps back.
    var isSpinning = false
    let action: () -> Void

    /// Center of `arrow.clockwise`'s circle inside the symbol's bounds, measured from the rendered glyph.
    /// The arrowhead makes the bounds taller than the circle, so turning around their middle makes it wobble.
    private static let spinAnchor = UnitPoint(x: 0.49, y: 0.525)

    @State private var turns = 0.0
    @State private var isTurning = false
    /// Mirrors `isSpinning` so the end of each turn reads the current value, not the one captured when it started.
    @State private var keepsSpinning = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(Tokens.Typography.icon(weight))
                .foregroundStyle(color)
                .rotationEffect(.degrees(turns * 360), anchor: Self.spinAnchor)
                .frame(width: Tokens.Metrics.iconButtonSize, height: Tokens.Metrics.iconButtonSize)
        }
        .buttonStyle(HoverHighlightStyle(cornerRadius: Tokens.Metrics.iconButtonRadius))
        .accessibilityLabel(accessibilityLabel)
        .onChange(of: isSpinning, initial: true) {
            keepsSpinning = isSpinning
            if isSpinning { turn() }
        }
    }

    private func turn() {
        guard !isTurning else { return }
        isTurning = true
        withAnimation(.linear(duration: 1)) {
            turns += 1
        } completion: {
            isTurning = false
            if keepsSpinning { turn() }
        }
    }
}
