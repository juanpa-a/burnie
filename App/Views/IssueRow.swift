import SwiftUI

/// A section's problem, below its meters. Supports `code` in markdown.
struct IssueRow: View {
    let message: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "exclamationmark.circle")
                .font(Tokens.Typography.issueIcon)
            Text((try? AttributedString(markdown: message)) ?? AttributedString(message))
                .font(Tokens.Typography.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Tokens.Palette.fg2)
    }
}
