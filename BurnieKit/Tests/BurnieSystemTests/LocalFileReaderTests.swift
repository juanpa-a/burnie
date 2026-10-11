import Foundation
import Testing
@testable import BurnieSystem

final class LocalFileReaderTests {
    let root = FileManager.default.temporaryDirectory.appending(path: "burnie-tests-\(UUID().uuidString)")
    let reader = LocalFileReader()

    init() throws {
        try FileManager.default.createDirectory(at: root.appending(path: "project/subagents"), withIntermediateDirectories: true)
        try Data("first\nsecond\n".utf8).write(to: root.appending(path: "project/session.jsonl"))
        try Data("agent\n".utf8).write(to: root.appending(path: "project/subagents/agent.jsonl"))
        try Data("ignored".utf8).write(to: root.appending(path: "project/notes.txt"))
    }

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    @Test func listsMatchingFilesRecursively() throws {
        let names = try reader.list(root, ext: "jsonl").map(\.lastPathComponent).sorted()
        #expect(names == ["agent.jsonl", "session.jsonl"])
    }

    @Test func missingDirectoryThrows() {
        #expect(throws: (any Error).self) { try reader.list(root.appending(path: "missing"), ext: "jsonl") }
    }

    @Test func readsFromAnOffset() throws {
        let file = root.appending(path: "project/session.jsonl")
        #expect(try reader.attributes(file).size == 13)
        #expect(try reader.read(file, from: 6) == Data("second\n".utf8))
        #expect(try reader.read(file, from: 13).isEmpty)
    }
}
