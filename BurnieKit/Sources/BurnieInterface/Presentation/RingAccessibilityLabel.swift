import BurnieDomain
import Foundation

/// What VoiceOver reads for the menu bar icon (B-54).
public enum RingAccessibilityLabel {
    /// "Burnie usage", or "Burnie usage, Claude Code 64%" while the ring shows a provider among `providers`.
    public static func text(for ring: RingState, providers: [ProviderPanel]) -> String {
        guard case .visible(let id, let percent) = ring, let panel = providers.first(where: { $0.id == id }) else {
            return "Burnie usage"
        }
        return "Burnie usage, \(panel.descriptor.displayName) \(percent)%"
    }
}
