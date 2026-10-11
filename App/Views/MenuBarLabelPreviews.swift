#if DEBUG
import BurnieCore
import SwiftUI

// The icon on a light and a dark menu bar.

@MainActor
private func label(_ ring: RingState) -> some View {
    HStack(spacing: 24) {
        ForEach([ColorScheme.light, .dark], id: \.self) { scheme in
            MenuBarLabel(ring: ring)
                .padding(8)
                .background(.bar)
                .environment(\.colorScheme, scheme)
        }
    }
    .padding(24)
}

#Preview("Flame") { label(.hidden) }
#Preview("Ring at 64%") { label(.visible(.claude, fraction: 0.64)) }
#Preview("Ring at 92%") { label(.visible(.claude, fraction: 0.92)) }
#endif
