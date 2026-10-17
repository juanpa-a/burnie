// expect: none
import SwiftUI

/// Every color, font and measurement the components use; literal values live only here.
enum DesignTokens {
    enum Metrics {
        static let iconButtonSize: CGFloat = 28
        static let contentInset: CGFloat = 16
    }

    enum Palette {
        static let pop = Color(red: 0.95, green: 0.42, blue: 0.2)
    }

    enum Shapes {
        static let chip = RoundedRectangle(cornerRadius: 4)
    }
}
