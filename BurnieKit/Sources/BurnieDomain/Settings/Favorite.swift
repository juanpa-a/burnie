import Foundation

/// The provider whose usage the menu bar ring shows: one at a time, and only among the enabled ones.
public enum Favorite {
    /// The stored favorite if it's on; otherwise the only provider on; otherwise none. Derived, never stored (B-52).
    public static func effective(stored: ProviderID?, enabled: Set<ProviderID>) -> ProviderID? {
        if let stored, enabled.contains(stored) { return stored }
        return enabled.count == 1 ? enabled.first : nil
    }

    /// The stored favorite after tapping `id`'s heart: it replaces the previous one, or clears it if it already was. A
    /// provider that's off can't be marked (B-52).
    public static func toggling(_ id: ProviderID, stored: ProviderID?, enabled: Set<ProviderID>) -> ProviderID? {
        guard enabled.contains(id) else { return stored }
        return id == stored ? nil : id
    }

    /// The ring only appears with the switch on, an effective favorite, and a ready snapshot with meters: a favorite
    /// still loading or failed shows the flame alone, never an empty ring that reads as 0%. A team's meter never
    /// reaches the menu bar, so the ring follows only a primary meter of the user's own (B-53).
    public static func ring(
        stored: ProviderID?,
        enabled: Set<ProviderID>,
        showRing: Bool,
        states: [ProviderID: ProviderState]
    ) -> RingState {
        guard showRing,
              let favorite = effective(stored: stored, enabled: enabled),
              let meter = states[favorite]?.snapshot?.meters?.primary,
              meter.scope == .own
        else { return .hidden }
        // Whole percents, so the icon isn't redrawn for changes nobody can see.
        return .visible(favorite, percent: Int((meter.fill.value * 100).rounded()))
    }
}
