import BurnieDomain
import Foundation

/// Tokens per local day from Cursor's usage events CSV. Only `Date` and `Total Tokens` are used (B-47).
enum CursorUsageEvents {
    static func dailyTokens(csv: String, in days: ClosedRange<LocalDay>, calendar: Calendar) throws(ProviderIssue) -> [LocalDay: Tokens] {
        let rows = CSVParser.rows(in: csv)
        guard let header = rows.first else { return [:] }
        guard let dateColumn = header.firstIndex(of: "Date"), let tokensColumn = header.firstIndex(of: "Total Tokens") else {
            throw .unexpectedResponse("Cursor CSV without Date or Total Tokens")
        }
        var totals: [LocalDay: Tokens] = [:]
        for row in rows.dropFirst() where row.indices.contains(dateColumn) && row.indices.contains(tokensColumn) {
            guard let date = ISO8601DateParser.date(from: row[dateColumn]),
                  let tokens = Int(row[tokensColumn].replacingOccurrences(of: ",", with: "")) else { continue }
            let day = LocalDay(date, in: calendar)
            if days.contains(day) {
                totals[day, default: .zero] += Tokens(tokens)
            }
        }
        return totals
    }
}
