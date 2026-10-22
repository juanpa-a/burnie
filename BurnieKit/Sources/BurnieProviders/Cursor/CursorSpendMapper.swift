import BurnieDomain
import Foundation

/// Money spent per local day from Cursor's usage events: the sum of what each event charged the plan.
///
/// All or nothing: a single event without a valid charge makes the whole sum unknown,
/// because a partial sum would read as less spent than there was (B-47).
/// Only the member's: events of more than one owner make it unknown too, since they would count the team.
enum CursorSpendMapper {
    /// Every day in `days` is present, with 0 if it had no events.
    static func dailySpentCents(
        from events: [CursorUsageEventsDTO.Event],
        in days: ClosedRange<LocalDay>,
        calendar: Calendar
    ) throws(ProviderIssue) -> [LocalDay: Cents] {
        guard Set(events.compactMap { $0.owningUser?.value }).count <= 1 else {
            throw .unexpectedResponse("Cursor usage events of more than one member")
        }
        var totals = Dictionary(uniqueKeysWithValues: days.map { ($0, 0.0) })
        for event in events {
            let (day, cents) = try charge(of: event, calendar: calendar)
            if days.contains(day) {
                totals[day, default: 0] += cents
            }
        }
        // Rounded once per day, so many sub-cent charges still add up.
        return totals.mapValues { Cents(Int($0.rounded())) }
    }

    private static func charge(of event: CursorUsageEventsDTO.Event, calendar: Calendar) throws(ProviderIssue) -> (LocalDay, Double) {
        guard let milliseconds = event.timestamp?.value, milliseconds.isFinite,
              let cents = event.chargedCents?.value, cents.isFinite, cents >= 0 else {
            throw .unexpectedResponse("Cursor event without a valid charge")
        }
        return (LocalDay(Date(timeIntervalSince1970: milliseconds / 1_000), in: calendar), cents)
    }
}
