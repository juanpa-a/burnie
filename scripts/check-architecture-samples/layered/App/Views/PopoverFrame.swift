// expect: C-4
import SwiftUI

/// The popover with its width typed in.
struct PopoverFrame<Content: View>: View {
    let content: Content

    var body: some View {
        content.frame(width: 340)
    }
}
