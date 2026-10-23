#if DEBUG
import BurnieDomain
import BurnieInterface
import BurnieProviders
import Foundation

/// The canvas's sample data, over the real providers' descriptors: Saturday, October 10, 2026, 2:00 PM in Mexico City.
enum PreviewData {
    static let now = Date(timeIntervalSince1970: 1_791_662_400)
    // A fixed identifier that always exists.
    static let clock = PreviewClock(now: now, timeZone: TimeZone(identifier: "America/Mexico_City")!)
    static let today = LocalDay(now, in: clock.timeZone)

    static let claude = ClaudeProvider.descriptor
    static let cursor = CursorProvider.descriptor

    /// 2 h 46 m into the 5-hour session, 53 hours into the week, 9 days into a 31-day billing cycle.
    static let session = DateInterval(start: now.addingTimeInterval(-(2 * 3_600 + 46 * 60)), duration: 5 * 3_600)
    static let week = DateInterval(start: now.addingTimeInterval(-53 * 3_600), duration: 7 * 86_400)
    static let cursorCycle = DateInterval(start: now.addingTimeInterval(-9 * 86_400), duration: 31 * 86_400)

    /// The session runs ahead of an even pace and the week behind it.
    static let claudeLimits = LimitsPart(
        plan: PlanName(rawValue: "MAX"),
        meters: MeterSet(
            primary: Meter(id: claude.meters[0].id, fill: Fraction(0.64), value: .percent(64), caption: .resetsIn(session.end), period: session),
            others: [Meter(id: claude.meters[1].id, fill: Fraction(0.24), value: .percent(24), caption: .resetsAt(week.end), period: week)]
        )
    )

    static let cursorLimits = LimitsPart(
        plan: PlanName(rawValue: "PRO"),
        meters: MeterSet(
            primary: Meter(id: cursor.meters[0].id, fill: Fraction(0.2), value: .percent(20), caption: .cycleEnds(cursorCycle.end), period: cursorCycle),
            others: [Meter(id: cursor.meters[1].id, fill: Fraction(0.8), value: .percent(80), caption: .cycleEnds(cursorCycle.end), period: cursorCycle)]
        ),
        features: SnapshotFeatures(onDemand: Meter(
            id: cursor.meters[3].id, fill: Fraction(0.67), value: .money(used: Cents(1_340), limit: Cents(2_000)), caption: .cycleEnds(cursorCycle.end)
        ))
    )

    /// A dollar budget instead of pools.
    static let cursorEnterpriseLimits = LimitsPart(
        plan: PlanName(rawValue: "ENTERPRISE"),
        meters: MeterSet(primary: Meter(
            id: cursor.meters[2].id, fill: Fraction(0.37), value: .money(used: Cents(18_420), limit: Cents(50_000)),
            caption: .cycleEnds(cursorCycle.end), period: cursorCycle
        )),
        features: SnapshotFeatures(onDemand: Meter(
            id: cursor.meters[3].id, fill: .zero, value: .money(used: .zero, limit: Cents(100_000)), caption: .onDemandIdle
        ))
    )

    static let claudeSnapshot = snapshot(claude.id, limits: claudeLimits, today: TodayUsage(tokens: Tokens(1_250_000)))
    static let cursorSnapshot = snapshot(cursor.id, limits: cursorLimits, today: TodayUsage(tokens: Tokens(2_400_000)))
    static let cursorEnterprise = snapshot(cursor.id, limits: cursorEnterpriseLimits, today: TodayUsage(tokens: Tokens(2_400_000)))

    static let history: UsageHistory = {
        var history = UsageHistory()
        history.record(week([420_000, 980_000, 0, 1_200_000, 640_000, 1_100_000, 1_250_000].map(Tokens.init)), for: claude.id, today: today)
        history.record(week([1_100_000, 0, 4_000_000, 2_800_000, 1_100_000, 1_900_000, 2_400_000].map(Tokens.init)), for: cursor.id, today: today)
        return history
    }()

    /// A snapshot with limits, stamped `minutesAgo` before now.
    static func snapshot(_ provider: ProviderID, limits: LimitsPart, today: TodayUsage?, minutesAgo: Double = 2) -> UsageSnapshot {
        let view = Stamped(limits, at: now.addingTimeInterval(-minutesAgo * 60))
        return UsageSnapshot(provider: provider, content: .limits(view: view, today: today))
    }

    /// The app state the views would render for these provider states and switches.
    static func state(
        claude claudeState: ProviderState = .ready(claudeSnapshot),
        cursor cursorState: ProviderState = .ready(cursorSnapshot),
        enabled: Set<ProviderID>? = nil,
        favorite: ProviderID? = nil,
        showRing: Bool = true,
        showWeekChart: Bool = true,
        hiddenFeatures: Set<FeatureToggle> = [],
        history: UsageHistory = history,
        availableUpdate: String? = nil
    ) -> AppState {
        let enabled = enabled ?? [claude.id, cursor.id]
        let settings = AppSettings(enabled: enabled, favorite: favorite, showRing: showRing, showWeekChart: showWeekChart, hiddenFeatures: hiddenFeatures)
        let states = [claude.id: claudeState, cursor.id: cursorState]
        let effective = Favorite.effective(stored: favorite, enabled: enabled)
        let order = [claude.id, cursor.id].filter(enabled.contains)
        let snapshots = order.compactMap { states[$0]?.snapshot }
        let cycleStarts = Dictionary(uniqueKeysWithValues: order.compactMap { id in
            states[id]?.snapshot?.meters?.cycle.map { (id, LocalDay($0.start, in: clock.timeZone)) }
        })
        return AppState(
            providers: [
                panel(claude, state: claudeState, settings: settings, effective: effective, renewal: "Couldn't refresh sign-in. Run `claude` in Terminal and log in again.", source: "~/.claude"),
                panel(cursor, state: cursorState, settings: settings, effective: effective, renewal: nil, source: nil),
            ],
            ring: Favorite.ring(stored: favorite, enabled: enabled, showRing: showRing, states: states),
            weekChart: showWeekChart && !order.isEmpty
                ? WeekChart.make(
                    history: history,
                    providers: order,
                    today: today,
                    cycleStarts: cycleStarts
                )
                : nil,
            lastUpdated: snapshots.map(\.fetchedAt).max(),
            isRefreshing: false,
            settings: settings,
            visibleToggles: FeatureToggle.allCases.filter { toggle in snapshots.contains { $0.features.has(toggle) } },
            launchAtLogin: false,
            availableUpdate: availableUpdate
        )
    }

    private static func panel(
        _ descriptor: ProviderDescriptor,
        state: ProviderState,
        settings: AppSettings,
        effective: ProviderID?,
        renewal: String?,
        source: String?
    ) -> ProviderPanel {
        ProviderPanel(
            descriptor: descriptor,
            isEnabled: settings.enabled.contains(descriptor.id),
            isFavorite: effective == descriptor.id,
            state: state.hiding(settings.hiddenFeatures),
            renewalFailedCopy: renewal,
            sourceLocation: source
        )
    }

    /// One value per day of the week ending today.
    private static func week<Value>(_ values: [Value]) -> [LocalDay: Value] {
        Dictionary(uniqueKeysWithValues: values.enumerated().map { (today.advanced(by: $0.offset - values.count + 1), $0.element) })
    }
}
#endif
