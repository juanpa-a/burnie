// expect: G-6
import BurnieDomain
import Foundation

/// Reads the weekday with the system calendar instead of one passed in.
public enum DayFormatter {
    public static func weekday(of date: Date) -> Int {
        Calendar.current.component(.weekday, from: date)
    }
}
