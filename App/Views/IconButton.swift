import SwiftUI

/// A 28×28 button with an SF Symbol, like the ones in the header.
struct IconButton: View {
    let systemName: String
    let accessibilityLabel: String
    var weight: Font.Weight = .medium
    var color = Tokens.Palette.fg2
    /// Spins while true (Refresh in progress) and always finishes the turn it's on,
    /// so a quick refresh still shows one full turn and the symbol never snaps back.
    var isSpinning = false
    let action: () -> Void

    /// Center of `arrow.clockwise`'s circle inside the symbol's 14×16 pt bounds at 13 pt medium, measured from the rendered glyph.
    /// The arrowhead makes the bounds taller than the circle, so turning around their middle makes it wobble.
    private static let spinAnchor = UnitPoint(x: 0.5, y: 0.57)

    @State private var spin: Spin?

    var body: some View {
        Button(action: action) {
            TimelineView(.animation(paused: spin == nil)) { timeline in
                Image(systemName: systemName)
                    .font(Tokens.Typography.icon(weight))
                    .foregroundStyle(color)
                    .rotationEffect(spin?.angle(at: timeline.date) ?? .zero, anchor: Self.spinAnchor)
                    .frame(width: Tokens.Metrics.iconButtonSize, height: Tokens.Metrics.iconButtonSize)
            }
        }
        .buttonStyle(HoverHighlightStyle(cornerRadius: Tokens.Metrics.iconButtonRadius))
        .accessibilityLabel(accessibilityLabel)
        .onChange(of: isSpinning, initial: true) {
            if isSpinning {
                startSpinning()
            } else {
                spin?.stop(at: .now)
            }
        }
        .task(id: spin?.end) {
            await pauseAfterLastTurn()
        }
    }

    private func startSpinning() {
        if spin == nil {
            spin = Spin(startingAt: .now)
        } else {
            spin?.resume()
        }
    }

    /// Lets the timeline rest once the arrow does. A new `end`, or leaving the screen, cancels the wait.
    private func pauseAfterLastTurn() async {
        guard let end = spin?.end else { return }
        try? await Task.sleep(for: .seconds(end.timeIntervalSinceNow))
        guard !Task.isCancelled else { return }
        spin = nil
    }
}
