import BurnieInterface
import SwiftUI

/// A footer row: text on the left and an accessory on the right.
public struct FooterItem: View {
    public enum Accessory: Sendable {
        /// ↗: opens something outside Burnie.
        case external
        case shortcut(String)
    }

    let title: String
    let accessory: Accessory?
    let action: () -> Void

    public init(title: String, accessory: Accessory?, action: @escaping () -> Void) {
        self.title = title
        self.accessory = accessory
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Palette.fg)
                Spacer()
                accessoryView
                    .foregroundStyle(DesignTokens.Palette.fg2)
            }
            .padding(.horizontal, DesignTokens.Insets.control)
            .frame(height: DesignTokens.Metrics.footerItemHeight)
        }
        .buttonStyle(HoverHighlightStyle(cornerRadius: DesignTokens.Metrics.footerItemRadius))
    }

    @ViewBuilder
    private var accessoryView: some View {
        switch accessory {
        case .external:
            Image(systemName: "arrow.up.right").font(DesignTokens.Typography.caption)
        case .shortcut(let keys):
            Text(keys).font(DesignTokens.Typography.body)
        case nil:
            EmptyView()
        }
    }
}

#Preview {
    PreviewFrame {
        FooterItem(title: PreviewValues.footerTitle, accessory: .external) {}
        FooterItem(title: Copy.quit, accessory: .shortcut(Copy.quitShortcut)) {}
    }
}
