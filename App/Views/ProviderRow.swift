import BurnieCore
import SwiftUI

/// A row on the providers screen: tile, name with status, the favorite's heart, and the switch.
struct ProviderRow: View {
    let provider: ProviderID
    let status: String
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            tile
            VStack(alignment: .leading, spacing: 2) {
                Text(provider.displayName)
                    .font(Tokens.Typography.title)
                    .foregroundStyle(Tokens.Palette.fg)
                    .opacity(isOn ? 1 : Tokens.offOpacity)
                Text(status)
                    .font(Tokens.Typography.caption)
                    .foregroundStyle(Tokens.Palette.fg2)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            favoriteButton
            Toggle("Track \(provider.displayName)", isOn: $isOn)
                .toggleStyle(BurnieSwitchStyle(onColor: accent))
                .labelsHidden()
        }
        .padding(.horizontal, 10)
        .frame(height: Tokens.Metrics.providerRowHeight)
        .contentShape(RoundedRectangle(cornerRadius: Tokens.Metrics.providerRowRadius))
    }

    /// Only a provider that's on can be the favorite.
    private var favoriteButton: some View {
        IconButton(
            systemName: isFavorite ? "heart.fill" : "heart",
            accessibilityLabel: isFavorite ? "Remove \(provider.displayName) as favorite" : "Mark \(provider.displayName) as favorite",
            color: isFavorite ? Tokens.Palette.favorite : Tokens.Palette.fg2,
            action: onToggleFavorite
        )
        .accessibilityAddTraits(isFavorite ? .isSelected : [])
        .opacity(isOn ? 1 : Tokens.favoriteOffOpacity)
        .disabled(!isOn)
    }

    private var tile: some View {
        RoundedRectangle(cornerRadius: Tokens.Metrics.tileRadius)
            .fill(isOn ? accent.opacity(Tokens.tileTintOpacity) : Tokens.Palette.tileOff)
            .frame(width: Tokens.Metrics.tileSize, height: Tokens.Metrics.tileSize)
            .overlay {
                Circle()
                    .fill(isOn ? accent : Tokens.Palette.dotOff)
                    .frame(width: Tokens.Metrics.tileDot, height: Tokens.Metrics.tileDot)
            }
    }

    private var accent: Color {
        Tokens.Palette.accent(provider)
    }
}
