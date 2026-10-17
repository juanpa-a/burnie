// expect: G-6
import SwiftUI

/// Spins like IconButton, but that exception belongs to IconButton alone.
struct SpinnerView: View {
    @State private var spin: Spin?

    var body: some View {
        Image(systemName: "arrow.clockwise")
            .onAppear { spin = Spin(startingAt: .now) }
    }
}
