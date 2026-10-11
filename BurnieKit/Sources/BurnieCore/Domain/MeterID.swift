import Foundation

public enum MeterID: String, Codable, Sendable {
    // Claude
    case session, weekly
    // Cursor: two pools, or a single meter on team plans; on-demand only when enabled.
    case cursorModels, otherModels, included, onDemand
}
