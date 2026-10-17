import BurnieDomain
import BurnieInterface
import SwiftUI

/// One meter: label and value, a bar in the provider's color with a tick at an even pace, and a caption.
public struct MeterView: View {
    let label: String
    /// nil while the first data loads: the value reads "—" and the bar is empty.
    let value: (amount: String, limit: String?)?
    let fill: Fraction
    /// Where the bar would be at an even pace; nil hides the tick (B-3).
    let pace: Fraction?
    /// The part of the fill past the pace, drawn in the over-pace color (B-5).
    let overPace: Fraction
    let caption: String?
    let accent: ColorPair
    /// Dims the value and the bar (B-6).
    let isStale: Bool
    @Environment(\.colorScheme) private var colorScheme

    public init(
        label: String,
        value: (amount: String, limit: String?)?,
        fill: Fraction,
        pace: Fraction?,
        overPace: Fraction,
        caption: String?,
        accent: ColorPair,
        isStale: Bool = false
    ) {
        self.label = label
        self.value = value
        self.fill = fill
        self.pace = pace
        self.overPace = overPace
        self.caption = caption
        self.accent = accent
        self.isStale = isStale
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.meterLines) {
            HStack {
                Text(label)
                    .font(DesignTokens.Typography.meterLabel)
                    .foregroundStyle(DesignTokens.Palette.fg)
                Spacer()
                valueText
                    .opacity(dataOpacity)
            }
            bar
                .opacity(dataOpacity)
            if let caption {
                Text(caption)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Palette.fg2)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var dataOpacity: Double {
        isStale ? DesignTokens.Opacity.stale : DesignTokens.Opacity.opaque
    }

    private var valueText: Text {
        guard let value else {
            return Text(Copy.noValue).font(DesignTokens.Typography.meterValue).foregroundColor(DesignTokens.Palette.fg2)
        }
        let amount = Text(value.amount).font(DesignTokens.Typography.meterValue).foregroundColor(DesignTokens.Palette.fg)
        guard let limit = value.limit else { return amount.monospacedDigit() }
        return (amount + Text(limit).font(DesignTokens.Typography.meterLabel).foregroundColor(DesignTokens.Palette.fg2)).monospacedDigit()
    }

    private var bar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: DesignTokens.Metrics.meterBarRadius)
                    .fill(DesignTokens.Palette.track)
                fillBar(width: geometry.size.width)
            }
            .overlay(alignment: .leading) {
                if let pace {
                    paceMarker(at: geometry.size.width * pace.value)
                }
            }
        }
        .frame(height: DesignTokens.Metrics.meterBarHeight)
    }

    /// The provider's color up to an even pace, and the over-pace color for whatever runs past it.
    private func fillBar(width: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(DesignTokens.Palette.overPace)
            Rectangle()
                .fill(DesignTokens.Palette.accent(accent, in: colorScheme))
                .frame(width: width * (fill.value - overPace.value))
        }
        .frame(width: width * fill.value)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Metrics.meterBarRadius))
    }

    private func paceMarker(at x: CGFloat) -> some View {
        Capsule()
            .fill(DesignTokens.Palette.paceMarker)
            .frame(width: DesignTokens.Metrics.paceMarkerWidth, height: DesignTokens.Metrics.paceMarkerHeight)
            .offset(x: x - DesignTokens.Metrics.paceMarkerWidth / 2)
    }
}

#if DEBUG
#Preview {
    PreviewFrame {
        MeterView(
            label: PreviewValues.label, value: PreviewValues.value, fill: PreviewValues.fill, pace: PreviewValues.pace,
            overPace: PreviewValues.overPace, caption: PreviewValues.caption, accent: PreviewValues.orange
        )
        MeterView(
            label: PreviewValues.label, value: PreviewValues.money, fill: PreviewValues.fill, pace: nil,
            overPace: .zero, caption: nil, accent: PreviewValues.blue, isStale: true
        )
        MeterView(label: PreviewValues.label, value: nil, fill: .zero, pace: nil, overPace: .zero, caption: nil, accent: PreviewValues.orange)
    }
}
#endif
