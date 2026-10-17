// expect: G-5
import BurnieDomain
import SwiftUI

/// Draws one provider differently from the rest.
struct ProviderSection: View {
    let id: ProviderID

    var body: some View {
        switch id {
        case .cursor: EmptyView()
        default: EmptyView()
        }
    }
}
