import BurnieDomain

extension SpecificIssue {
    /// Cursor encrypts its session at rest and Burnie can't read the Keychain item that opens it: the user denied
    /// access, or the item isn't there. Frozen: cached snapshots use it (SPEC section 12).
    static let missingKeychainAccess = SpecificIssue(code: "missingKeychainAccess")
}
