// expect: C-5
import SwiftUI

/// A button whose title is typed in.
struct RefreshButton: View {
    let action: () -> Void

    var body: some View {
        Button("Refresh", action: action)
    }
}
