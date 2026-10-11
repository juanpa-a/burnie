import Foundation

extension ProviderID {
    /// The app's name in section titles and text: "Claude Code", "Cursor".
    public var displayName: String {
        switch self {
        case .claude: "Claude Code"
        case .cursor: "Cursor"
        }
    }

    /// Short name for the chart legend: "Claude", "Cursor".
    public var shortName: String {
        switch self {
        case .claude: "Claude"
        case .cursor: "Cursor"
        }
    }

    /// The footer item that opens the provider's usage page.
    public var dashboardTitle: String {
        switch self {
        case .claude: "Open Claude usage page"
        case .cursor: "Open Cursor dashboard"
        }
    }

    public var dashboardURL: URL {
        switch self {
        case .claude: URL(string: "https://claude.ai/settings/usage")!
        case .cursor: URL(string: "https://cursor.com/dashboard/spending")!
        }
    }

    /// The meters drawn empty while the first data loads.
    public var placeholderMeters: [MeterID] {
        switch self {
        case .claude: [.session, .weekly]
        case .cursor: [.cursorModels, .otherModels]
        }
    }
}
