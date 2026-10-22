import BurnieDomain
import BurnieInterface
import Foundation

extension ProviderDescriptor {
    /// An invented provider that reads local files: its healthy line names where.
    public static let alpha = ProviderDescriptor(
        id: .alpha,
        displayName: "Alpha Code",
        shortName: "Alpha",
        color: ColorPair(light: RGB(red: 0.8, green: 0.4, blue: 0.2), dark: RGB(red: 0.9, green: 0.5, blue: 0.3)),
        dashboard: DashboardLink(title: "Open Alpha usage page", url: URL(string: "https://alpha.example/usage")!),
        meters: [MeterDescriptor(id: .daily, label: "Daily"), MeterDescriptor(id: .monthly, label: "Monthly")],
        placeholderMeters: [.daily, .monthly],
        copy: ProviderCopy(
            notFound: "Alpha Code not found.",
            signInExpired: "Alpha sign-in expired.",
            specific: [.alphaScope: "Alpha can't read limits."],
            status: { "Reading local logs · \($0.sourceLocation ?? "~/.alpha")" }
        )
    )

    /// An invented provider with a plan and a money budget: its healthy line names the plan.
    public static let beta = ProviderDescriptor(
        id: .beta,
        displayName: "Beta",
        shortName: "Beta",
        color: ColorPair(light: RGB(red: 0.2, green: 0.4, blue: 0.8), dark: RGB(red: 0.3, green: 0.5, blue: 0.9)),
        dashboard: DashboardLink(title: "Open Beta dashboard", url: URL(string: "https://beta.example/dashboard")!),
        meters: [MeterDescriptor(id: .budget, label: "Budget"), MeterDescriptor(id: .extra, label: "On-demand")],
        placeholderMeters: [.budget],
        copy: ProviderCopy(
            notFound: "Beta not found.",
            signInExpired: "Beta session expired.",
            status: { context in context.plan.map { "Signed in · \($0.rawValue.capitalized) plan" } ?? "Signed in" }
        )
    )
}
