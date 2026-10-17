// expect: none
import BurnieApplication
import BurnieInfra
import BurnieInterface
import BurnieProviders
import Foundation
import SwiftUI

/// The one place that builds adapters, provider bundles and the app model, and may read the system clock.
@MainActor
enum AppComposition {
    static func makeModel() -> AppModel {
        let clock = SystemClock()
        let started = Date()
        let zone = TimeZone.current
        let bundles = [ClaudeProvider.bundle(ClaudePorts(clock: clock, startedAt: started, timeZone: zone))]
        return AppModel.live(AppEnvironment(clock: clock, bundles: bundles))
    }
}
