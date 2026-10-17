import BurnieDomain

extension ProviderID {
    /// Frozen: settings and file names use it (SPEC section 12). Internal, so nothing outside the providers can
    /// compare against it (G-5).
    static let cursor = ProviderID(rawValue: "cursor")
}
