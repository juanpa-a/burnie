import BurnieDomain

extension LocalDay {
    /// A test's literal day, like `.day("2026-10-10")`; a typo stops the run instead of returning nil.
    public static func day(_ iso: String) -> LocalDay {
        guard let day = LocalDay(iso: iso) else { fatalError("Not a yyyy-MM-dd day: \(iso)") }
        return day
    }
}
