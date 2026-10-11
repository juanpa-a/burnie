import Foundation

extension MeterID {
    public var label: String {
        switch self {
        case .session: "Session · 5h"
        case .weekly: "Weekly"
        case .cursorModels: "Cursor Models"
        case .otherModels: "Other Models"
        case .included: "Included usage"
        case .onDemand: "On-demand"
        }
    }
}
