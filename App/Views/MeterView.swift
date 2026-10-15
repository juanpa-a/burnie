import BurnieCore
import SwiftUI

/// One meter: label and value, a bar in the provider's color with a tick at an even pace, and a caption.
struct MeterView: View {
    let label: String
    /// nil while the first data loads: value "—" and an empty bar.
    let value: (amount: String, limit: String?)?
    let fraction: Double
    /// Where the bar would be at an even pace; nil hides the tick.
    let elapsed: Double?
    let caption: String?
    let accent: Color
    var isStale = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(Tokens.Typography.meterLabel)
                    .foregroundStyle(Tokens.Palette.fg)
                Spacer()
                valueText
                    .opacity(isStale ? Tokens.staleOpacity : 1)
            }
            bar
                .opacity(isStale ? Tokens.staleOpacity : 1)
            if let caption {
                Text(caption)
                    .font(Tokens.Typography.caption)
                    .foregroundStyle(Tokens.Palette.fg2)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var valueText: Text {
        guard let value else {
            return Text("—").font(Tokens.Typography.meterValue).foregroundColor(Tokens.Palette.fg2)
        }
        let amount = Text(value.amount).font(Tokens.Typography.meterValue).foregroundColor(Tokens.Palette.fg)
        guard let limit = value.limit else { return amount.monospacedDigit() }
        return (amount + Text(limit).font(Tokens.Typography.meterLabel).foregroundColor(Tokens.Palette.fg2)).monospacedDigit()
    }

    private var bar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: Tokens.Metrics.meterBarRadius)
                    .fill(Tokens.Palette.track)
                fill(width: geometry.size.width)
            }
            .overlay(alignment: .leading) {
                if let elapsed {
                    paceMarker(at: geometry.size.width * elapsed)
                }
            }
        }
        .frame(height: Tokens.Metrics.meterBarHeight)
    }

    /// The provider's color up to an even pace, and the alert color for whatever runs past it.
    private func fill(width: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Tokens.Palette.overPace)
            Rectangle()
                .fill(accent)
                .frame(width: width * onPaceFraction)
        }
        .frame(width: width * fraction)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Metrics.meterBarRadius))
    }

    /// The part of the fill that isn't ahead of an even pace: all of it without a tick.
    private var onPaceFraction: Double {
        min(fraction, elapsed ?? fraction)
    }

    private func paceMarker(at x: CGFloat) -> some View {
        Capsule()
            .fill(Tokens.Palette.paceMarker)
            .frame(width: Tokens.Metrics.paceMarkerWidth, height: Tokens.Metrics.paceMarkerHeight)
            .offset(x: x - Tokens.Metrics.paceMarkerWidth / 2)
    }
}
