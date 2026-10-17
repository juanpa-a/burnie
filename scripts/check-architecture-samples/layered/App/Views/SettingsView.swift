// expect: G-6
import BurnieInterface
import SwiftUI

/// Formats with the system locale instead of SwiftUI's environment.
struct SettingsView: View {
    let percent: Double

    var body: some View {
        Text(percent.formatted(.percent.locale(Locale.current)))
    }
}
