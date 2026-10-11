import SwiftUI

/// A footer row: text on the left and an accessory on the right.
struct FooterItem: View {
    enum Accessory {
        /// ↗: opens something outside Burnie.
        case external
        case shortcut(String)
    }

    let title: String
    let accessory: Accessory?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Tokens.Typography.body)
                    .foregroundStyle(Tokens.Palette.fg)
                Spacer()
                accessoryView
                    .foregroundStyle(Tokens.Palette.fg2)
            }
            .padding(.horizontal, 10)
            .frame(height: Tokens.Metrics.footerItemHeight)
        }
        .buttonStyle(HoverHighlightStyle(cornerRadius: Tokens.Metrics.footerItemRadius))
    }

    @ViewBuilder
    private var accessoryView: some View {
        switch accessory {
        case .external:
            Image(systemName: "arrow.up.right").font(Tokens.Typography.caption)
        case .shortcut(let keys):
            Text(keys).font(Tokens.Typography.body)
        case nil:
            EmptyView()
        }
    }
}
