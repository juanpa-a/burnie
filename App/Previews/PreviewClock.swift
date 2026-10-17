#if DEBUG
import BurnieInterface
import Foundation

/// A clock stopped where the previews' sample data is, so every preview draws the same ages and countdowns.
struct PreviewClock: Clock {
    let now: Date
    let timeZone: TimeZone
}
#endif
