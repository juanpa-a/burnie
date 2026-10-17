import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct TokenCountFormatterTests {
    @Test(arguments: [
        (0, "0"), (980, "980"), (999, "999"),
        (1_000, "1K"), (9_600, "9.6K"), (9_999, "9.9K"),
        (10_000, "10K"), (640_000, "640K"), (999_999, "999K"),
        (1_000_000, "1M"), (1_050_000, "1M"), (1_800_000, "1.8M"), (9_999_999, "9.9M"),
        (12_000_000, "12M"), (12_999_999, "12M"),
    ])
    func abbreviatesRoundingDown(count: Int, expected: String) {
        #expect(TokenCountFormatter(locale: .enUS).string(from: count) == expected)
    }

    @Test func usesTheLocaleDecimalSeparator() {
        #expect(TokenCountFormatter(locale: Locale(identifier: "de_DE")).string(from: 1_800_000) == "1,8M")
    }
}
