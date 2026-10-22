import Foundation

/// One page of `cursor.com/api/dashboard/get-filtered-usage-events`, keeping only what adds up the money spent and whose
/// it was.
///
/// Cursor sends some numbers as strings, so every number here accepts both. A query without events answers `{}`.
struct CursorUsageEventsDTO: Decodable {
    struct Event: Decodable {
        /// Unix milliseconds.
        let timestamp: Number?
        /// What the event charged the plan, in cents; may carry fractions of a cent.
        let chargedCents: Number?
        /// The id of the member the event belongs to, only compared with the others' (B-47).
        let owningUser: Number?
    }

    /// A JSON number, or a string that holds one.
    struct Number: Decodable {
        let value: Double

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode(Double.self) {
                self.value = value
            } else if let value = Double(try container.decode(String.self)) {
                self.value = value
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not a number")
            }
        }
    }

    /// The events matching the query across every page.
    let totalUsageEventsCount: Number?
    /// Missing on an empty page.
    let usageEventsDisplay: [Event]?
}
