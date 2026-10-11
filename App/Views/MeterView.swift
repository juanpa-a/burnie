import BurnieCore
import SwiftUI

/// One meter: label and value, a bar in the provider's color, and a caption.
struct MeterView: View {
    let label: String
    /// nil while the first data loads: value "—" and an empty bar.
    let value: (amount: String, limit: String?)?
    let fraction: Double
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
                RoundedRectangle(cornerRadius: Tokens.Metrics.meterBarRadius)
                    .fill(accent)
                    .frame(width: geometry.size.width * fraction)
            }
        }
        .frame(height: Tokens.Metrics.meterBarHeight)
    }
}
