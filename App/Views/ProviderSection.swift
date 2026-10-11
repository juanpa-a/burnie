import BurnieCore
import SwiftUI

/// A provider's section: title with plan and today's tokens, its meters, and the issue row if any.
struct ProviderSection: View {
    let provider: ProviderID
    let state: ProviderState
    let now: Date
    let timeZone: TimeZone
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            titleRow
            switch state {
            case .loading:
                ForEach(provider.placeholderMeters, id: \.self) { id in
                    MeterView(label: id.label, value: nil, fraction: 0, caption: nil, accent: accent)
                }
            case .ready(let snapshot):
                ForEach(snapshot.meters) { meter in
                    meterView(meter, isStale: snapshot.isStale(at: now))
                }
                issueRow(snapshot.issue)
            case .failed(let issue):
                issueRow(issue)
            }
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 16, trailing: 16))
    }

    private var titleRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(accent)
                .frame(width: Tokens.Metrics.providerDot, height: Tokens.Metrics.providerDot)
            Text(provider.displayName)
                .font(Tokens.Typography.title)
                .foregroundStyle(Tokens.Palette.fg)
            if let plan = snapshot?.plan {
                PlanChip(plan: plan)
            }
            Spacer(minLength: 8)
            if let snapshot, let tokens = snapshot.tokensToday {
                Text("\(TokenCountFormatter(locale: locale).string(from: tokens)) tokens today")
                    .font(Tokens.Typography.caption)
                    .foregroundStyle(Tokens.Palette.fg2)
                    .monospacedDigit()
                    .opacity(snapshot.isStale(at: now) ? Tokens.staleOpacity : 1)
            }
        }
    }

    private func meterView(_ meter: Meter, isStale: Bool) -> some View {
        MeterView(
            label: meter.id.label,
            value: MeterValueFormatter(locale: locale).parts(for: meter.value),
            fraction: meter.fraction,
            caption: MeterCaptionFormatter(locale: locale, timeZone: timeZone).string(for: meter.caption, now: now),
            accent: accent,
            isStale: isStale
        )
    }

    @ViewBuilder
    private func issueRow(_ issue: ProviderIssue?) -> some View {
        if let message = issue?.message(for: provider) {
            IssueRow(message: message)
        }
    }

    private var snapshot: UsageSnapshot? {
        guard case .ready(let snapshot) = state else { return nil }
        return snapshot
    }

    private var accent: Color {
        Tokens.Palette.accent(provider)
    }
}
