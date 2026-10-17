import BurnieComponents
import BurnieInterface
import SwiftUI

/// The Ring in menu bar switch on the providers screen. It only works with a favorite; without one it reads off, keeps
/// its stored value, and says how to mark one (B-74).
struct RingInMenuBarRow: View {
    /// The provider the ring follows, marked or implicit.
    let favorite: ProviderDescriptor?
    @Binding var isOn: Bool

    var body: some View {
        SwitchRow(title: Copy.ringInMenuBar, subtitle: subtitle, isOn: $isOn)
            .disabled(favorite == nil)
            .padding(DesignTokens.Insets.settingRow)
    }

    /// Always visible, so there's no doubt whose ring it is.
    private var subtitle: Text {
        guard let favorite else {
            let heart = Text(Image(systemName: "heart")).font(DesignTokens.Typography.captionSymbol)
            let words = Copy.ringWithoutFavorite
            return Text("\(words.beforeHeart) \(heart) \(words.afterHeart)")
        }
        return Text(Copy.ringShows(favorite.displayName))
    }
}
