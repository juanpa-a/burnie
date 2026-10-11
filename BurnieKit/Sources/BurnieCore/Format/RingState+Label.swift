import Foundation

extension RingState {
    /// What VoiceOver reads for the menu bar icon: "Burnie usage", or "Burnie usage, Claude Code 64%".
    public var accessibilityLabel: String {
        switch self {
        case .hidden:
            "Burnie usage"
        case .visible(let provider, let fraction):
            "Burnie usage, \(provider.displayName) \(Int((fraction * 100).rounded()))%"
        }
    }
}
