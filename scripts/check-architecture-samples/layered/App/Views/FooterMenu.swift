// expect: C-5
import BurnieApplication
import SwiftUI

/// A menu with its copy typed in.
struct FooterMenu: View {
    let model: AppModel

    var body: some View {
        Menu {
            Text("Quit Burnie")
        } label: {
            Image(systemName: "gearshape")
        }
        .accessibilityLabel("Settings")
    }
}
