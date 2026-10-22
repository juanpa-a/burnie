import BurnieDomain
import Foundation

/// The latest limits and the latest activity of one provider, each nil until it first arrives.
struct ProviderParts: Equatable, Sendable {
    var limits: Latest<LimitsPart>?
    var activity: Latest<ActivityPart>?

    /// Records a task's outcome: a part under its own kind, a failure under the kind the task yields (B-11).
    mutating func record(_ outcome: Result<Part, ProviderIssue>, of kind: PartKind, at date: Date) {
        switch outcome {
        case .success(.limits(let part)): limits = Self.recording(.success(part), at: date, after: limits)
        case .success(.activity(let part)): activity = Self.recording(.success(part), at: date, after: activity)
        case .failure(let issue) where kind == .limits: limits = Self.recording(.failure(issue), at: date, after: limits)
        case .failure(let issue): activity = Self.recording(.failure(issue), at: date, after: activity)
        }
    }

    private static func recording<Value>(_ outcome: Result<Value, ProviderIssue>, at date: Date, after previous: Latest<Value>?) -> Latest<Value> {
        previous.map { $0.recording(outcome, at: date) } ?? Latest(outcome, at: date)
    }
}
