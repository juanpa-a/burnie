import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct AppSettingsTests {
    @Test("B-50 first launch: every provider enabled, ring on, week chart on, on-demand shown, no favorite")
    func firstLaunchDefaults() {
        let settings = AppSettings.defaults(enabled: [.alpha, .beta])
        #expect(settings == AppSettings(enabled: [.alpha, .beta], favorite: nil, showRing: true, showWeekChart: true, hiddenFeatures: []))
    }
}
