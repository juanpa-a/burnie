import BurnieDomain
import Foundation

/// A meter kind as its provider declares it.
public struct MeterDescriptor: Hashable, Sendable {
    public let id: MeterID
    /// "Session · 5h"
    public let label: String

    public init(id: MeterID, label: String) {
        self.id = id
        self.label = label
    }
}
