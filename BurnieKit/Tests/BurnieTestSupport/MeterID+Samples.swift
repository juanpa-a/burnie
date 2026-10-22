import BurnieDomain

extension MeterID {
    /// Invented meter kinds for tests below `BurnieProviders`.
    public static let daily = MeterID(rawValue: "daily")
    public static let monthly = MeterID(rawValue: "monthly")
    public static let budget = MeterID(rawValue: "budget")
    public static let extra = MeterID(rawValue: "extra")
}
