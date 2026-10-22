import BurnieInterface
import SwiftUI
import Testing
@testable import BurnieComponents

/// The module's colors and the flame come from its own compiled asset catalog (SPEC 18, question 4).
struct DesignTokensTests {
    @Test func theAssetCatalogShipsWithTheModule() {
        #expect(Bundle.module.url(forResource: "Assets", withExtension: "car") != nil)
    }

    @Test func aProviderAccentFollowsTheColorScheme() {
        let pair = ColorPair(light: RGB(red: 1, green: 0, blue: 0), dark: RGB(red: 0, green: 0, blue: 1))
        #expect(DesignTokens.Palette.accent(pair, in: .light) == Color(.sRGB, red: 1, green: 0, blue: 0))
        #expect(DesignTokens.Palette.accent(pair, in: .dark) == Color(.sRGB, red: 0, green: 0, blue: 1))
    }
}
