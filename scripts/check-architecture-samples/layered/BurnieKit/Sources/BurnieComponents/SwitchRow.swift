// expect: C-5
import SwiftUI

/// A row whose subtitle is typed in.
struct SwitchRow: View {
    let title: String

    var body: some View {
        SettingRow(title: title, subtitle: "Shows the ring in the menu bar")
    }
}
