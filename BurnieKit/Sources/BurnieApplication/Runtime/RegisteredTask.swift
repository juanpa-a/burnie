import BurnieDomain
import Foundation

/// A refresh task as the reducer keeps it: without its closure, which stays with the interpreter.
struct RegisteredTask: Equatable, Sendable {
    let name: String
    let part: PartKind
    let policy: RefreshPolicy
}
