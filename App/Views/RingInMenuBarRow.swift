import BurnieCore
import SwiftUI

/// The Ring in menu bar switch on the providers screen. It only works with a favorite;
/// without one it reads off and says how to mark one.
struct RingInMenuBarRow: View {
    /// The provider the ring follows, explicit or implicit.
    let favorite: ProviderID?
    @Binding var isOn: Bool

    var body: some View {
        SwitchRow(title: "Ring in menu bar", subtitle: subtitle, isOn: $isOn, isEnabled: favorite != nil)
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }

    /// Always visible, so there's no doubt whose ring it is.
    private var subtitle: Text {
        guard let favorite else {
            let heart = Text(Image(systemName: "heart")).font(Tokens.Typography.captionSymbol)
            return Text("Mark a provider with \(heart) to show its ring")
        }
        return Text("Shows \(favorite.displayName) usage")
    }
}
