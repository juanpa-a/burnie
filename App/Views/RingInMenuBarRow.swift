import BurnieCore
import SwiftUI

/// The Ring in menu bar switch on the providers screen. It only works with a favorite;
/// without one it reads off and says how to mark one.
struct RingInMenuBarRow: View {
    /// The provider the ring follows, explicit or implicit.
    let favorite: ProviderID?
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ring in menu bar")
                    .font(Tokens.Typography.title)
                    .foregroundStyle(Tokens.Palette.fg)
                    .opacity(hasFavorite ? 1 : Tokens.offOpacity)
                subtitle
                    .font(Tokens.Typography.caption)
                    .foregroundStyle(Tokens.Palette.fg2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Toggle("Ring in menu bar", isOn: hasFavorite ? $isOn : .constant(false))
                .toggleStyle(BurnieSwitchStyle(onColor: Tokens.Palette.switchOn))
                .labelsHidden()
                .opacity(hasFavorite ? 1 : Tokens.disabledSwitchOpacity)
                .disabled(!hasFavorite)
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }

    private var hasFavorite: Bool {
        favorite != nil
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
