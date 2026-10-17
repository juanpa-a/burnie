// expect: none
import BurnieDomain
import BurnieInterface
import SwiftUI

/// Values and closures in, tokens for every measurement; zero needs no token.
struct MeterRow: View {
    let title: String
    let percent: Int
    let onRefresh: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { _ in
            VStack(spacing: 0) {
                Label(title, systemImage: "gauge")
                Text("\(percent)%")
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .keyboardShortcut("r")
            }
            .padding(0)
            .frame(maxWidth: .infinity)
        }
    }
}
