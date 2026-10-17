// expect: C-4
import SwiftUI

/// A track drawn with a literal color and line width.
struct MeterTrack: View {
    var body: some View {
        Capsule()
            .stroke(Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 2)
    }
}
