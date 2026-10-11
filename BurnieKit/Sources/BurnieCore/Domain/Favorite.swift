import Foundation

/// The provider whose usage the menu bar ring shows. Only one at a time, and only among the enabled ones.
public enum Favorite {
    /// The stored favorite if it's on; otherwise the only provider on; otherwise none.
    /// The implicit favorite is derived, never stored.
    public static func effective(stored: ProviderID?, enabled: Set<ProviderID>) -> ProviderID? {
        if let stored, enabled.contains(stored) { return stored }
        return enabled.count == 1 ? enabled.first : nil
    }

    /// The stored favorite after tapping `id`'s heart: it replaces the previous one, or clears it if it already was.
    /// A provider that's off can't be marked.
    public static func toggling(_ id: ProviderID, stored: ProviderID?, enabled: Set<ProviderID>) -> ProviderID? {
        guard enabled.contains(id) else { return stored }
        return id == stored ? nil : id
    }

    /// The ring only appears with the switch on, an effective favorite, and at least one meter to show:
    /// a favorite still loading or failed shows the flame alone, never an empty ring that reads as 0%.
    public static func ring(
        stored: ProviderID?,
        enabled: Set<ProviderID>,
        showRing: Bool,
        states: [ProviderID: ProviderState]
    ) -> RingState {
        guard showRing,
              let favorite = effective(stored: stored, enabled: enabled),
              case .ready(let snapshot)? = states[favorite],
              let meter = snapshot.meters.first
        else { return .hidden }
        // Whole percents, so the icon isn't redrawn for changes nobody can see.
        return .visible(favorite, fraction: (meter.fraction * 100).rounded() / 100)
    }
}
