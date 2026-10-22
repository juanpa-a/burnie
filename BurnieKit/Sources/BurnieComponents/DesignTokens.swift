import BurnieInterface
import SwiftUI

/// Colors, type and measurements from the "Usage Menu Bar" canvas. Components and views never use raw colors or
/// magic numbers; a provider's accent comes from its descriptor.
public enum DesignTokens {
    /// Color sets in the module's asset catalog, each with a dark variant.
    public enum Palette {
        public static let pop = Color("pop", bundle: .module)
        public static let fg = Color("fg", bundle: .module)
        public static let fg2 = Color("fg2", bundle: .module)
        public static let line = Color("line", bundle: .module)
        public static let track = Color("track", bundle: .module)
        public static let chip = Color("chip", bundle: .module)
        public static let hover = Color("hover", bundle: .module)
        public static let toggleOff = Color("toggleOff", bundle: .module)
        public static let tileOff = Color("tileOff", bundle: .module)
        public static let dotOff = Color("dotOff", bundle: .module)
        /// The favorite's filled heart.
        public static let favorite = Color("favorite", bundle: .module)
        /// The stretch of a meter's fill that runs past an even pace.
        public static let overPace = Color("overPace", bundle: .module)
        /// The tick on a meter's bar where an even pace would be.
        public static let paceMarker = fg2
        /// A switch that isn't a provider's (Launch at login, Ring in menu bar) uses the system accent, like a native one.
        public static let switchOn = Color.accentColor
        /// The dot on the gear when a new Burnie is available.
        public static let updateBadge = Color.blue
        public static let switchKnob = Color.white
        public static let switchKnobShadow = Color.black.opacity(0.3)
        /// Under the week chart's tooltip, so it lifts off the popover it shares a color with.
        public static let tooltipShadow = Color.black.opacity(0.12)
        /// The menu bar glyph, drawn in black to become a template image.
        public static let menuBarGlyph = Color.black
        /// Behind the previews' light and dark copies.
        public static let previewBackdrop = Color.gray.opacity(0.3)

        /// A provider's accent in `scheme`.
        public static func accent(_ pair: ColorPair, in scheme: ColorScheme) -> Color {
            let rgb = scheme == .dark ? pair.dark : pair.light
            return Color(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue)
        }
    }

    public enum Typography {
        public static let title = Font.system(size: 13, weight: .semibold)
        public static let body = Font.system(size: 13)
        public static let meterLabel = Font.system(size: 12)
        public static let meterValue = Font.system(size: 12, weight: .semibold)
        public static let caption = Font.system(size: 11)
        public static let captionStrong = Font.system(size: 11, weight: .semibold)
        public static let chip = Font.system(size: 10, weight: .semibold)
        public static let day = Font.system(size: 10)
        public static let today = Font.system(size: 10, weight: .bold)
        public static let issueIcon = Font.system(size: 11)
        /// A symbol inside a caption: the heart in "Mark a provider with ♥ to show its ring".
        public static let captionSymbol = Font.system(size: 10)
        /// "Usage" and "Providers", a hair tighter than other titles.
        public static let screenTitleTracking: CGFloat = -0.1
        public static let chipTracking: CGFloat = 0.3
        /// "Activity" over the chart.
        public static let chartTitleTracking: CGFloat = 0.2

        public static func icon(_ weight: Font.Weight) -> Font {
            .system(size: 13, weight: weight)
        }
    }

    public enum Metrics {
        public static let popoverWidth: CGFloat = 340
        public static let contentInset: CGFloat = 16
        public static let dividerInset: CGFloat = 12
        public static let dividerThickness: CGFloat = 1
        public static let iconButtonSize: CGFloat = 28
        public static let iconButtonRadius: CGFloat = 6
        public static let chipButtonHeight: CGFloat = 24
        public static let chipRadius: CGFloat = 4
        public static let providerDot: CGFloat = 8
        public static let meterBarHeight: CGFloat = 6
        public static let meterBarRadius: CGFloat = 3
        public static let paceMarkerWidth: CGFloat = 2
        /// Taller than the bar, so the tick still shows over a full fill.
        public static let paceMarkerHeight: CGFloat = 10
        public static let chartHeight: CGFloat = 40
        public static let chartBarWidth: CGFloat = 6
        public static let chartBarRadius: CGFloat = 2
        /// An empty day's mark, and the shortest bar of a day with usage (B-43).
        public static let chartBarMinimum: CGFloat = 2
        public static let legendDot: CGFloat = 6
        public static let tooltipRadius: CGFloat = 6
        public static let tooltipBorder: CGFloat = 0.5
        public static let tooltipShadowRadius: CGFloat = 6
        public static let tooltipShadowOffset: CGFloat = 2
        public static let footerItemHeight: CGFloat = 26
        public static let footerItemRadius: CGFloat = 6
        public static let providerRowHeight: CGFloat = 52
        public static let providerRowRadius: CGFloat = 8
        public static let tileSize: CGFloat = 28
        public static let tileRadius: CGFloat = 7
        public static let tileDot: CGFloat = 10
        public static let switchSize = CGSize(width: 38, height: 22)
        public static let switchKnob: CGFloat = 18
        /// Between the knob and the switch's edge.
        public static let switchKnobInset: CGFloat = 2
        public static let switchKnobShadowRadius: CGFloat = 1.5
        public static let switchKnobShadowOffset: CGFloat = 1
        public static let updateBadge: CGFloat = 6
        /// From the icon button's top-right corner, so the dot sits on the gear's corner.
        public static let updateBadgeInset: CGFloat = 5
    }

    /// Gaps inside stacks, named by what they separate.
    public enum Spacing {
        /// A title over its subtitle.
        public static let textLines: CGFloat = 2
        /// The header's icon buttons, side by side.
        public static let headerButtons: CGFloat = 2
        /// The back button and the screen title.
        public static let backButton: CGFloat = 4
        /// An icon or a spinner and its text.
        public static let iconAndText: CGFloat = 6
        /// A meter's label, bar and caption.
        public static let meterLines: CGFloat = 6
        /// Things that belong together: a section's title row, a message and its button.
        public static let related: CGFloat = 8
        /// A row's columns: tile, text, controls.
        public static let rowItems: CGFloat = 12
        /// A provider section's title row and meters.
        public static let sectionItems: CGFloat = 14
        /// The chart's title row and columns.
        public static let chartRows: CGFloat = 10
        /// The chart's day columns.
        public static let chartColumns: CGFloat = 6
        /// One day's bars, side by side.
        public static let chartBars: CGFloat = 2
        /// A day's bars and its letter.
        public static let chartLabel: CGFloat = 5
        /// The legend's providers.
        public static let legendItems: CGFloat = 10
        /// A legend dot, its name and its total.
        public static let legendDot: CGFloat = 4
        /// The tooltip's day and its rows.
        public static let tooltipLines: CGFloat = 3
        /// A tooltip row's name and its values, at least.
        public static let tooltipValues: CGFloat = 12
        /// The tooltip and the day it's over.
        public static let tooltipGap: CGFloat = 6
        /// The previews' light and dark copies.
        public static let previews: CGFloat = 24
    }

    /// Padding around regions, named by region.
    public enum Insets {
        public static let usageHeader = EdgeInsets(top: 14, leading: 16, bottom: 10, trailing: 12)
        public static let providersHeader = EdgeInsets(top: 12, leading: 8, bottom: 10, trailing: 16)
        public static let providerSection = EdgeInsets(top: 14, leading: 16, bottom: 16, trailing: 16)
        public static let weekChart = EdgeInsets(top: 12, leading: 16, bottom: 14, trailing: 16)
        public static let tooltip = EdgeInsets(top: 7, leading: 9, bottom: 7, trailing: 9)
        public static let settingRow = EdgeInsets(top: 12, leading: Metrics.contentInset, bottom: 12, trailing: Metrics.contentInset)
        /// Around a list of rows: the footer, the providers.
        public static let list: CGFloat = 6
        /// Inside a button or row, left and right.
        public static let control: CGFloat = 10
        public static let chipVertical: CGFloat = 2
        public static let chipHorizontal: CGFloat = 6
        /// Above and below the empty state.
        public static let emptyState: CGFloat = 28
        public static let preview: CGFloat = 24
    }

    /// The menu bar icon, from the "Ícono en la barra" artboard: a 24-unit grid drawn at 18 pt.
    public enum MenuBar {
        public static let iconSize: CGFloat = 18
        private static let unit = iconSize / 24
        public static let ringDiameter = 19 * unit
        public static let ringLineWidth = 2.4 * unit
        public static let ringTrackOpacity = 0.3
        public static let flameInRingSize = 0.6 * iconSize
        /// The flame sits 0.4 units below the ring's center.
        public static let flameInRingOffset = 0.4 * unit
        /// The ring starts at 12 o'clock.
        public static let ringStart = Angle.degrees(-90)
    }

    public enum Opacity {
        public static let opaque = 1.0
        /// Values whose data is more than 30 minutes old (B-6).
        public static let stale = 0.6
        /// A disabled provider's name, and the Ring in menu bar title without a favorite.
        public static let off = 0.6
        /// The heart of a provider that's off.
        public static let favoriteOff = 0.3
        /// A switch that can't be used, like Ring in menu bar without a favorite.
        public static let disabledSwitch = 0.45
        /// An enabled provider's tile: its accent color at this opacity.
        public static let tileTint = 0.18
        /// The week chart's other days while one is hovered (B-77).
        public static let chartDimmed = 0.35
    }

    public enum Motion {
        public static let switchToggle = Animation.easeInOut(duration: 0.15)
        /// Between the usage and providers screens.
        public static let screenChange = Animation.easeInOut(duration: 0.18)
        /// The week chart's days dimming as the pointer moves over them.
        public static let chartHover = Animation.easeOut(duration: 0.12)
        /// How often the time-dependent text (ages, countdowns) is drawn again without a refresh.
        public static let clockTick: TimeInterval = 30
    }
}
