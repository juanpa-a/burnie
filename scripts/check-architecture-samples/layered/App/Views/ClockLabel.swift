// expect: G-3 V-3
import BurnieInfra
import SwiftUI

/// Views read time from the app model's clock, not from an adapter.
struct ClockLabel: View {
    var body: some View { EmptyView() }
}
