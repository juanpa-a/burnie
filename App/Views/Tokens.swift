import BurnieCore
import SwiftUI

/// Colors, type and measurements from the "Usage Menu Bar" canvas. Views never use raw hex values or magic numbers.
enum Tokens {
    /// Color Sets in `Assets.xcassets`, each with a dark variant.
    enum Palette {
        static let pop = Color("pop")
        static let fg = Color("fg")
        static let fg2 = Color("fg2")
        static let line = Color("line")
        static let track = Color("track")
        static let chip = Color("chip")
        static let hover = Color("hover")
        static let toggleOff = Color("toggleOff")
        static let tileOff = Color("tileOff")
        static let dotOff = Color("dotOff")
        /// The favorite's filled heart.
        static let favorite = Color("favorite")
        /// A switch that isn't a provider's (Launch at login, Ring in menu bar) uses the system accent, like a native switch.
        static let switchOn = Color.accentColor

        static func accent(_ provider: ProviderID) -> Color {
            switch provider {
            case .claude: Color("claude")
            case .cursor: Color("cursor")
            }
        }
    }

    enum Typography {
        static let title = Font.system(size: 13, weight: .semibold)
        static let body = Font.system(size: 13)
        static let meterLabel = Font.system(size: 12)
        static let meterValue = Font.system(size: 12, weight: .semibold)
        static let caption = Font.system(size: 11)
        static let captionStrong = Font.system(size: 11, weight: .semibold)
        static let chip = Font.system(size: 10, weight: .semibold)
        static let day = Font.system(size: 10)
        static let today = Font.system(size: 10, weight: .bold)
        static let issueIcon = Font.system(size: 11)
        /// A symbol inside a caption: the heart in "Mark a provider with ♥ to show its ring".
        static let captionSymbol = Font.system(size: 10)

        static func icon(_ weight: Font.Weight) -> Font {
            .system(size: 13, weight: weight)
        }
    }

    enum Metrics {
        static let popoverWidth: CGFloat = 340
        static let contentInset: CGFloat = 16
        static let dividerInset: CGFloat = 12
        static let iconButtonSize: CGFloat = 28
        static let iconButtonRadius: CGFloat = 6
        static let providerDot: CGFloat = 8
        static let meterBarHeight: CGFloat = 6
        static let meterBarRadius: CGFloat = 3
        static let chartHeight: CGFloat = 40
        static let chartBarWidth: CGFloat = 6
        static let chartBarRadius: CGFloat = 2
        static let chartBarMinimum: CGFloat = 2
        static let legendDot: CGFloat = 6
        static let footerItemHeight: CGFloat = 26
        static let footerItemRadius: CGFloat = 6
        static let providerRowHeight: CGFloat = 52
        static let settingRowInsets = EdgeInsets(top: 12, leading: contentInset, bottom: 12, trailing: contentInset)
        static let providerRowRadius: CGFloat = 8
        static let tileSize: CGFloat = 28
        static let tileRadius: CGFloat = 7
        static let tileDot: CGFloat = 10
        static let switchSize = CGSize(width: 38, height: 22)
        static let switchKnob: CGFloat = 18
    }

    /// The menu bar icon, from the "Ícono en la barra" artboard: a 24-unit grid drawn at 18 pt.
    enum MenuBar {
        static let iconSize: CGFloat = 18
        private static let unit = iconSize / 24
        static let ringDiameter = 19 * unit
        static let ringLineWidth = 2.4 * unit
        static let ringTrackOpacity = 0.3
        static let flameInRingSize = 0.6 * iconSize
        /// The flame sits 0.4 units below the ring's center.
        static let flameInRingOffset = 0.4 * unit
    }

    /// Opacity of values whose data is more than 30 minutes old.
    static let staleOpacity = 0.6
    /// Opacity of a disabled provider's name, and of the Ring in menu bar title without a favorite.
    static let offOpacity = 0.6
    /// Opacity of the heart of a provider that's off.
    static let favoriteOffOpacity = 0.3
    /// Opacity of a switch that can't be used, like Ring in menu bar without a favorite.
    static let disabledSwitchOpacity = 0.45
    /// Tile background of an enabled provider: its accent color at this opacity.
    static let tileTintOpacity = 0.18
}
