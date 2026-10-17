// expect: G-3 V-3
import BurnieProviders
import SwiftUI

/// Views get providers through the app model, never by import.
struct RootView: View {
    var body: some View { EmptyView() }
}
