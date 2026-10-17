// expect: none
import SwiftUI
import Testing
@testable import BurnieComponents

@MainActor
struct MeterRowTests {
    @Test func renders() {
        let renderer = ImageRenderer(content: MeterRow(title: "Acme", percent: 40, onRefresh: {}).frame(width: 340))
        #expect(renderer.nsImage != nil)
    }
}
