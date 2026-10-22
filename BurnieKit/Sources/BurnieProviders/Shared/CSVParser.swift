import Foundation

/// CSV per RFC 4180: quoted fields may contain commas, line breaks and doubled quotes (`""`).
enum CSVParser {
    static func rows(in text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field: [UInt8] = []
        var isQuoted = false
        let bytes = Array(text.utf8)

        func endField() {
            row.append(String(decoding: field, as: UTF8.self))
            field.removeAll(keepingCapacity: true)
        }
        func endRow() {
            endField()
            rows.append(row)
            row.removeAll(keepingCapacity: true)
        }

        var index = 0
        while index < bytes.count {
            let byte = bytes[index]
            if isQuoted {
                if byte == quote, index + 1 < bytes.count, bytes[index + 1] == quote {
                    field.append(quote)
                    index += 1
                } else if byte == quote {
                    isQuoted = false
                } else {
                    field.append(byte)
                }
            } else {
                switch byte {
                case quote: isQuoted = true
                case comma: endField()
                case newline: endRow()
                case carriageReturn: break
                default: field.append(byte)
                }
            }
            index += 1
        }
        if !field.isEmpty || !row.isEmpty {
            endRow()
        }
        return rows
    }

    private static let quote = UInt8(ascii: "\"")
    private static let comma = UInt8(ascii: ",")
    private static let newline = UInt8(ascii: "\n")
    private static let carriageReturn = UInt8(ascii: "\r")
}
