import BurnieDomain

/// Frozen: cached snapshots use them (SPEC section 12).
extension MeterID {
    /// The Cursor Models pool (Auto, Composer) of individual plans.
    static let cursorModels = MeterID(rawValue: "cursorModels")
    /// The pool for every other model, on individual plans.
    static let otherModels = MeterID(rawValue: "otherModels")
    /// The single money budget of team and enterprise plans.
    static let included = MeterID(rawValue: "included")
    /// Spend past the included usage; only ever a snapshot feature.
    static let onDemand = MeterID(rawValue: "onDemand")
}
