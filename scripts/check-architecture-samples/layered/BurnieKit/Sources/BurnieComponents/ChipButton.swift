// expect: C-4
import SwiftUI

/// A chip with its padding typed in.
struct ChipButton: View {
    let title: String

    var body: some View {
        Text(title)
            .padding(.horizontal, 6)
    }
}
