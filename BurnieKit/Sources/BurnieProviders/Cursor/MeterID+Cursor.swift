import BurnieDomain

/// Frozen: cached snapshots use them (SPEC section 12).
extension MeterID {
    /// The Cursor Models pool (Auto, Composer) of individual plans.
    static let cursorModels = MeterID(rawValue: "cursorModels")
    /// The pool for every other model, on individual plans.
    static let otherModels = MeterID(rawValue: "otherModels")
    /// The member's own money budget on team and enterprise plans.
    static let included = MeterID(rawValue: "included")
    /// The whole team's shared budget, when the member has none of their own; scope team.
    static let teamPool = MeterID(rawValue: "teamPool")
    /// The member's own spend past the included usage; only ever a snapshot feature.
    static let onDemand = MeterID(rawValue: "onDemand")
    /// The whole team's spend past its included usage, when the member has no on-demand of their own; scope team, only
    /// ever a snapshot feature.
    static let teamOnDemand = MeterID(rawValue: "teamOnDemand")
}
