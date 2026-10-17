// expect: none
#if DEBUG
import BurnieInterface
import SwiftUI

/// Invented values for component previews; literal text and measurements are fine here.
enum PreviewValues {
    static let title = "Acme Code"
    static let caption = Text("Resets in 2 h")
    static let row = Label("Acme", systemImage: "flame").padding(4)
}
#endif
