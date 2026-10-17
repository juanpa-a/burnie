// expect: none
import BurnieApplication
import BurnieComponents
import BurnieInterface
import SwiftUI

/// Reads the app model and wires components; time comes from the model's clock.
struct UsageView: View {
    let model: AppModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { _ in
            MeterRow(title: model.state.title, percent: model.state.percent(at: model.clock.now), onRefresh: model.useCases.refresh)
                .padding(DesignTokens.Metrics.contentInset)
        }
    }
}
