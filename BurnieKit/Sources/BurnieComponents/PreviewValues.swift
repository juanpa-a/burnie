#if DEBUG
import BurnieDomain
import BurnieInterface
import Foundation

/// Invented values for the components' previews, never a real provider's (C-6). The one file C-4 and C-5 don't apply
/// to.
enum PreviewValues {
    /// Saturday, October 10, 2026, 2:00 PM in Mexico City.
    static let now = Date(timeIntervalSince1970: 1_791_662_400)
    // A fixed identifier that always exists.
    static let timeZone = TimeZone(identifier: "America/Mexico_City")!
    static let today = LocalDay(now, in: timeZone)

    static let orange = ColorPair(light: RGB(red: 0.94, green: 0.53, blue: 0.24), dark: RGB(red: 0.94, green: 0.53, blue: 0.24))
    static let blue = ColorPair(light: RGB(red: 0.3, green: 0.55, blue: 0.96), dark: RGB(red: 0.3, green: 0.55, blue: 0.96))

    static let northwind = descriptor(id: "northwind", name: "Northwind", color: orange)
    static let tailspin = descriptor(id: "tailspin", name: "Tailspin", color: blue)

    static let label = "Session · 5h"
    static let value = (amount: "64%", limit: String?.none)
    static let money = (amount: "$13.40", limit: String?(" / $20"))
    static let caption = "Resets in 2h 14m"
    static let status = "Reading local logs · ~/.northwind"
    static let offStatus = "Off"
    static let issue = "Limits paused. Open Northwind to refresh sign-in."
    static let failedRenewal = "Couldn't refresh sign-in. Run `northwind` in Terminal and log in again."
    static let switchTitle = "Ring in menu bar"
    static let switchSubtitle = "Shows Northwind usage"
    static let footerTitle = "Open Northwind usage page"
    static let plan = PlanName(rawValue: "MAX")

    static let fill = Fraction(0.64)
    static let pace = Fraction(0.55)
    static let overPace = Fraction(0.09)

    static let chart: WeekChart = {
        var history = UsageHistory()
        history.record(tokens([420_000, 980_000, 0, 1_200_000, 640_000, 1_100_000, 1_250_000]), for: northwind.id, today: today)
        history.record(tokens([1_100_000, 0, 4_000_000, 2_800_000, 1_100_000, 1_900_000, 2_400_000]), for: tailspin.id, today: today)
        return WeekChart.make(history: history, providers: [northwind.id, tailspin.id], today: today)
    }()

    /// One value per day of the week ending today.
    private static func tokens(_ values: [Int]) -> [LocalDay: Tokens] {
        Dictionary(uniqueKeysWithValues: values.enumerated().map { (today.advanced(by: $0.offset - values.count + 1), Tokens($0.element)) })
    }

    private static func descriptor(id: String, name: String, color: ColorPair) -> ProviderDescriptor {
        ProviderDescriptor(
            id: ProviderID(rawValue: id),
            displayName: name,
            shortName: name,
            color: color,
            // A literal URL, so it always parses.
            dashboard: DashboardLink(title: "Open \(name) usage page", url: URL(string: "https://example.com/usage")!),
            meters: [],
            placeholderMeters: [],
            copy: ProviderCopy(notFound: "\(name) not found.", signInExpired: "\(name) sign-in expired.", status: { _ in "Signed in" })
        )
    }
}
#endif
