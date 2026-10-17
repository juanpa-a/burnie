// expect: none
import BurnieCore
import BurnieSystem
import SwiftUI

/// Literal copy, measurements, colors and provider checks are still fine in today's views:
/// C-4, C-5, G-5 and the app's G-3 wake with the new modules.
struct UsageBadge: View {
    let provider: ProviderID

    var body: some View {
        Text("Hello")
            .font(.system(size: 13))
            .padding(6)
            .background(Color(red: 1, green: 0.5, blue: 0))
            .opacity(provider == .claude ? 1 : 0.5)
    }
}
