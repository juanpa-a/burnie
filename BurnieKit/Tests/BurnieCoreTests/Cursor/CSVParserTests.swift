import Testing
@testable import BurnieCore

struct CSVParserTests {
    @Test func splitsPlainFields() {
        #expect(CSVParser.rows(in: "a,b,c\n1,2,3\n") == [["a", "b", "c"], ["1", "2", "3"]])
    }

    @Test func keepsCommasNewlinesAndDoubledQuotesInsideQuotedFields() {
        let csv = "\"Errored, Not Charged\",\"gpt-5 \"\"high\"\"\",\"two\nlines\"\r\n\"\",last"
        #expect(CSVParser.rows(in: csv) == [["Errored, Not Charged", "gpt-5 \"high\"", "two\nlines"], ["", "last"]])
    }

    @Test func emptyTextHasNoRows() {
        #expect(CSVParser.rows(in: "").isEmpty)
    }
}
