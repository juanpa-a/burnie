import BurnieCore
import SwiftUI

/// The menu bar glyph, drawn in black to become a template image: the flame alone,
/// or the flame inside a ring that fills clockwise from 12 o'clock.
struct MenuBarIcon: View {
    let ring: RingState

    var body: some View {
        Group {
            switch ring {
            case .hidden:
                flame
            case .visible(_, let fraction):
                ringed(fraction)
            }
        }
        .frame(width: Tokens.MenuBar.iconSize, height: Tokens.MenuBar.iconSize)
        .foregroundStyle(.black)
    }

    private var flame: some View {
        Image("FlameGlyph").resizable()
    }

    private func ringed(_ fraction: Double) -> some View {
        ZStack {
            Circle()
                .stroke(lineWidth: Tokens.MenuBar.ringLineWidth)
                .opacity(Tokens.MenuBar.ringTrackOpacity)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(style: StrokeStyle(lineWidth: Tokens.MenuBar.ringLineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            flame
                .frame(width: Tokens.MenuBar.flameInRingSize, height: Tokens.MenuBar.flameInRingSize)
                .offset(y: Tokens.MenuBar.flameInRingOffset)
        }
        .frame(width: Tokens.MenuBar.ringDiameter, height: Tokens.MenuBar.ringDiameter)
    }
}
