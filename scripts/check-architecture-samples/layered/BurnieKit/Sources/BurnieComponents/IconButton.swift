// expect: none
import BurnieInterface
import SwiftUI

/// A button with an SF Symbol whose spin paces itself with the system clock, the one exception G-6 allows here.
struct IconButton: View {
    let systemName: String
    let accessibilityLabel: String
    let isSpinning: Bool
    let action: () -> Void
    @State private var spin: Spin?

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .frame(width: DesignTokens.Metrics.iconButtonSize, height: DesignTokens.Metrics.iconButtonSize)
        }
        .accessibilityLabel(accessibilityLabel)
        .onChange(of: isSpinning, initial: true) {
            if isSpinning {
                spin = Spin(startingAt: .now)
            } else {
                spin?.stop(at: .now)
            }
        }
        .task(id: spin?.end) {
            guard let end = spin?.end else { return }
            try? await Task.sleep(for: .seconds(end.timeIntervalSinceNow))
        }
    }
}
