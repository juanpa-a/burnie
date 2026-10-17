import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation

/// Panels over the invented descriptors, for the presentation tests.
enum PanelSamples {
    static let at = Date.iso("2026-10-10T20:00:00Z")

    static func panel(
        _ descriptor: ProviderDescriptor,
        isEnabled: Bool = true,
        state: ProviderState = .loading,
        sourceLocation: String? = nil
    ) -> ProviderPanel {
        ProviderPanel(
            descriptor: descriptor,
            isEnabled: isEnabled,
            isFavorite: false,
            state: state,
            renewalFailedCopy: nil,
            sourceLocation: sourceLocation
        )
    }

    /// A ready state with one meter, the plan given and the issue given.
    static func ready(_ provider: ProviderID, plan: String? = nil, issue: ProviderIssue? = nil) -> ProviderState {
        let meters = MeterSet(primary: Meter(id: .daily, fill: Fraction(0.5), value: .percent(50), caption: .noActiveSession))
        let limits = LimitsPart(plan: plan.map(PlanName.init(rawValue:)), meters: meters)
        return .ready(UsageSnapshot(provider: provider, content: .limits(view: Stamped(limits, at: at), today: nil), issue: issue))
    }
}
