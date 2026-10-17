import BurnieInterface
import SwiftUI

/// A row on the providers screen: tile, name with status, the favorite's heart, and the switch.
public struct ProviderRow: View {
    let displayName: String
    let status: String
    let accent: ColorPair
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    @Binding var isOn: Bool
    @Environment(\.colorScheme) private var colorScheme

    public init(
        displayName: String,
        status: String,
        accent: ColorPair,
        isFavorite: Bool,
        onToggleFavorite: @escaping () -> Void,
        isOn: Binding<Bool>
    ) {
        self.displayName = displayName
        self.status = status
        self.accent = accent
        self.isFavorite = isFavorite
        self.onToggleFavorite = onToggleFavorite
        _isOn = isOn
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.rowItems) {
            tile
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.textLines) {
                Text(displayName)
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Palette.fg)
                    .opacity(isOn ? DesignTokens.Opacity.opaque : DesignTokens.Opacity.off)
                Text(status)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Palette.fg2)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            favoriteButton
            Toggle(Copy.track(displayName), isOn: $isOn)
                .toggleStyle(BurnieSwitchStyle(onColor: color))
                .labelsHidden()
        }
        .padding(.horizontal, DesignTokens.Insets.control)
        .frame(height: DesignTokens.Metrics.providerRowHeight)
        .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Metrics.providerRowRadius))
    }

    /// Only a provider that's on can be the favorite (B-52).
    private var favoriteButton: some View {
        IconButton(
            systemName: isFavorite ? "heart.fill" : "heart",
            accessibilityLabel: isFavorite ? Copy.removeFavorite(displayName) : Copy.markFavorite(displayName),
            color: isFavorite ? DesignTokens.Palette.favorite : DesignTokens.Palette.fg2,
            action: onToggleFavorite
        )
        .accessibilityAddTraits(isFavorite ? .isSelected : [])
        .opacity(isOn ? DesignTokens.Opacity.opaque : DesignTokens.Opacity.favoriteOff)
        .disabled(!isOn)
    }

    private var tile: some View {
        RoundedRectangle(cornerRadius: DesignTokens.Metrics.tileRadius)
            .fill(isOn ? color.opacity(DesignTokens.Opacity.tileTint) : DesignTokens.Palette.tileOff)
            .frame(width: DesignTokens.Metrics.tileSize, height: DesignTokens.Metrics.tileSize)
            .overlay {
                Circle()
                    .fill(isOn ? color : DesignTokens.Palette.dotOff)
                    .frame(width: DesignTokens.Metrics.tileDot, height: DesignTokens.Metrics.tileDot)
            }
    }

    private var color: Color {
        DesignTokens.Palette.accent(accent, in: colorScheme)
    }
}

#Preview {
    PreviewFrame {
        ProviderRow(
            displayName: PreviewValues.northwind.displayName, status: PreviewValues.status, accent: PreviewValues.orange,
            isFavorite: true, onToggleFavorite: {}, isOn: .constant(true)
        )
        ProviderRow(
            displayName: PreviewValues.tailspin.displayName, status: Copy.quit, accent: PreviewValues.blue,
            isFavorite: false, onToggleFavorite: {}, isOn: .constant(false)
        )
    }
}
