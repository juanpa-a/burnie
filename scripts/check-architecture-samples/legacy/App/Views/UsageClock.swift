// expect: none
import SwiftUI

/// Redraws every 30 s; a TimelineView schedule may start from the system clock anywhere.
struct UsageClock: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            Text(context.date, style: .time)
        }
    }
}
