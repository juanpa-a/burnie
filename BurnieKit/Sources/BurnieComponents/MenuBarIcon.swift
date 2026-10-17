import BurnieDomain
import SwiftUI

/// The menu bar glyph, drawn in black to become a template image: the flame alone, or the flame inside a ring that
/// fills clockwise from 12 o'clock (B-53).
public struct MenuBarIcon: View {
    let ring: RingState

    public init(ring: RingState) {
        self.ring = ring
    }

    public var body: some View {
        Group {
            switch ring {
            case .hidden:
                flame
            case .visible(_, let percent):
                ringed(Double(percent) / 100)
            }
        }
        .frame(width: DesignTokens.MenuBar.iconSize, height: DesignTokens.MenuBar.iconSize)
        .foregroundStyle(DesignTokens.Palette.menuBarGlyph)
    }

    private var flame: some View {
        Image("FlameGlyph", bundle: .module).resizable()
    }

    private func ringed(_ fraction: Double) -> some View {
        ZStack {
            Circle()
                .stroke(lineWidth: DesignTokens.MenuBar.ringLineWidth)
                .opacity(DesignTokens.MenuBar.ringTrackOpacity)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(style: StrokeStyle(lineWidth: DesignTokens.MenuBar.ringLineWidth, lineCap: .round))
                .rotationEffect(DesignTokens.MenuBar.ringStart)
            flame
                .frame(width: DesignTokens.MenuBar.flameInRingSize, height: DesignTokens.MenuBar.flameInRingSize)
                .offset(y: DesignTokens.MenuBar.flameInRingOffset)
        }
        .frame(width: DesignTokens.MenuBar.ringDiameter, height: DesignTokens.MenuBar.ringDiameter)
    }
}

#Preview {
    PreviewFrame {
        MenuBarIcon(ring: .hidden)
        MenuBarIcon(ring: .visible(PreviewValues.northwind.id, percent: 64))
    }
}
