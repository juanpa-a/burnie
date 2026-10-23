import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct SnapshotContentTests {
    static let at = Date(timeIntervalSince1970: 1_791_662_100)
    static let meter = Meter(id: .daily, fill: Fraction(0.5), value: .percent(50), caption: .noActiveSession)
    static let limits = LimitsPart(plan: nil, meters: MeterSet(primary: meter))

    @Test func limitsEncodeTheirViewAndToday() throws {
        let content = SnapshotContent.limits(view: Stamped(Self.limits, at: Self.at), today: TodayUsage(tokens: Tokens(9)))
        let json = String(decoding: try JSONEncoder.persistence.encode(content), as: UTF8.self)
        #expect(json.hasPrefix(#"{"limits":{"today":{"tokens":9},"view":{"at":1791662100,"value":{"#))
        #expect(try JSONDecoder.persistence.decode(SnapshotContent.self, from: Data(json.utf8)) == content)
    }

    @Test func limitsWithoutTodayLeaveItOut() throws {
        let content = SnapshotContent.limits(view: Stamped(Self.limits, at: Self.at), today: nil)
        let json = String(decoding: try JSONEncoder.persistence.encode(content), as: UTF8.self)
        #expect(!json.contains("today"))
        #expect(try JSONDecoder.persistence.decode(SnapshotContent.self, from: Data(json.utf8)) == content)
    }

    @Test func activityOnlyEncodesItsStampedUsage() throws {
        let content = SnapshotContent.activityOnly(Stamped(TodayUsage(tokens: Tokens(9)), at: Self.at))
        let json = String(decoding: try JSONEncoder.persistence.encode(content), as: UTF8.self)
        #expect(json == #"{"activityOnly":{"at":1791662100,"value":{"tokens":9}}}"#)
        #expect(try JSONDecoder.persistence.decode(SnapshotContent.self, from: Data(json.utf8)) == content)
    }
}
