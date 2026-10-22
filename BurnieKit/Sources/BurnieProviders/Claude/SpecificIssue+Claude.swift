import BurnieDomain

extension SpecificIssue {
    /// A token without the `user:profile` scope, as `claude setup-token` makes: it can't read limits. Frozen: cached
    /// snapshots use it (SPEC section 12).
    static let missingScope = SpecificIssue(code: "missingScope")
}
