// expect: none
import SwiftUI

/// The spin of the refresh button paces itself with the system clock, which G-6 allows in this file only.
struct IconButton: View {
    let isSpinning: Bool
    @State private var spin: Spin?

    var body: some View {
        Image(systemName: "arrow.clockwise")
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
