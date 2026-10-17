import SwiftUI

/// A section's problem, below its meters. Supports `code` in markdown.
public struct IssueRow: View {
    let message: String

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.iconAndText) {
            Image(systemName: "exclamationmark.circle")
                .font(DesignTokens.Typography.issueIcon)
            Text((try? AttributedString(markdown: message)) ?? AttributedString(message))
                .font(DesignTokens.Typography.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(DesignTokens.Palette.fg2)
    }
}

#Preview {
    PreviewFrame {
        IssueRow(message: PreviewValues.failedRenewal)
    }
}
