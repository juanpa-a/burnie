import BurnieDomain
import Foundation

/// Everything static the rest of the app needs to know about a provider, filled once by the provider itself. Equal by
/// id: its copy holds a closure, and one provider has one descriptor.
public struct ProviderDescriptor: Sendable {
    public let id: ProviderID
    /// "Claude Code": section titles and text.
    public let displayName: String
    /// "Claude": the chart legend.
    public let shortName: String
    public let color: ColorPair
    /// The footer item that opens the provider's usage page.
    public let dashboard: DashboardLink
    /// Every meter kind the provider can report, in display order.
    public let meters: [MeterDescriptor]
    /// The meters drawn empty while the first data loads.
    public let placeholderMeters: [MeterID]
    public let copy: ProviderCopy

    public init(
        id: ProviderID,
        displayName: String,
        shortName: String,
        color: ColorPair,
        dashboard: DashboardLink,
        meters: [MeterDescriptor],
        placeholderMeters: [MeterID],
        copy: ProviderCopy
    ) {
        self.id = id
        self.displayName = displayName
        self.shortName = shortName
        self.color = color
        self.dashboard = dashboard
        self.meters = meters
        self.placeholderMeters = placeholderMeters
        self.copy = copy
    }

    /// A meter's label; a kind the descriptor doesn't declare reads as its id, never as an empty row.
    public func label(for meter: MeterID) -> String {
        meters.first { $0.id == meter }?.label ?? meter.rawValue
    }
}

extension ProviderDescriptor: Equatable {
    public static func == (lhs: ProviderDescriptor, rhs: ProviderDescriptor) -> Bool {
        lhs.id == rhs.id
    }
}
