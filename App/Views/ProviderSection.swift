import BurnieComponents
import BurnieDomain
import BurnieInterface
import SwiftUI

/// A provider's section: title with plan and today's usage, its meters and features, and the issue row if any.
struct ProviderSection: View {
    let panel: ProviderPanel
    let now: Date
    let timeZone: TimeZone
    /// Renews an expired sign-in through the provider's own app; nil if Burnie can't.
    let renewSignIn: (() async -> Bool)?
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sectionItems) {
            titleRow
            switch panel.state {
            case .loading:
                ForEach(descriptor.placeholderMeters, id: \.self) { id in
                    MeterView(label: descriptor.label(for: id), value: nil, fill: .zero, pace: nil, overPace: .zero, caption: nil, accent: descriptor.color)
                }
            case .ready(let snapshot):
                ForEach(meters(of: snapshot)) { meter in
                    meterView(meter, isStale: snapshot.isStale(at: now))
                }
                issueRow(snapshot.issue)
            case .failed(let issue):
                issueRow(issue)
            }
        }
        .padding(DesignTokens.Insets.providerSection)
    }

    private var descriptor: ProviderDescriptor {
        panel.descriptor
    }

    private var titleRow: some View {
        HStack(spacing: DesignTokens.Spacing.related) {
            Circle()
                .fill(DesignTokens.Palette.accent(descriptor.color, in: colorScheme))
                .frame(width: DesignTokens.Metrics.providerDot, height: DesignTokens.Metrics.providerDot)
            Text(descriptor.displayName)
                .font(DesignTokens.Typography.title)
                .foregroundStyle(DesignTokens.Palette.fg)
            if let plan = panel.state.snapshot?.plan {
                PlanChip(plan: plan)
            }
            Spacer(minLength: DesignTokens.Spacing.related)
            if let snapshot = panel.state.snapshot, let today = snapshot.today {
                Text(TodayUsageFormatter(locale: locale).string(for: today))
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Palette.fg2)
                    .monospacedDigit()
                    .opacity(snapshot.isStale(at: now) ? DesignTokens.Opacity.stale : DesignTokens.Opacity.opaque)
            }
        }
    }

    /// The meter set, then the features, like on-demand, after it.
    private func meters(of snapshot: UsageSnapshot) -> [Meter] {
        (snapshot.meters?.all ?? []) + [snapshot.features.onDemand].compactMap { $0 }
    }

    private func meterView(_ meter: Meter, isStale: Bool) -> some View {
        MeterView(
            label: descriptor.label(for: meter.id),
            value: MeterValueFormatter(locale: locale).parts(for: meter.value),
            fill: meter.fill,
            pace: meter.elapsedFraction(at: now),
            overPace: meter.overPace(at: now),
            caption: MeterCaptionFormatter(locale: locale, timeZone: timeZone).string(for: meter.caption, now: now),
            accent: descriptor.color,
            isStale: isStale
        )
    }

    @ViewBuilder
    private func issueRow(_ issue: ProviderIssue?) -> some View {
        if let issue, let message = IssueMessage.message(for: issue, copy: descriptor.copy) {
            if issue == .signInExpired, let renewSignIn, let failedMessage = panel.renewalFailedCopy {
                SignInRenewalRow(message: message, failedMessage: failedMessage, renew: renewSignIn)
            } else {
                IssueRow(message: message)
            }
        }
    }
}
