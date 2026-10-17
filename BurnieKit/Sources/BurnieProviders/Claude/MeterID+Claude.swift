import BurnieDomain

extension MeterID {
    /// The 5-hour session window. Frozen: cached snapshots use it (SPEC section 12).
    static let session = MeterID(rawValue: "session")
    /// The weekly window, across every model.
    static let weekly = MeterID(rawValue: "weekly")
}
