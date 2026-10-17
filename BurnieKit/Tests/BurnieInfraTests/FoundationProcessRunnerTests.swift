import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInfra

final class FoundationProcessRunnerTests {
    let home = FileManager.default.temporaryDirectory.appending(path: "burnie-runner-\(UUID().uuidString)")
    let log = RecordingDiagnosticsLog()

    deinit {
        try? FileManager.default.removeItem(at: home)
    }

    @Test func reportsTheExitStatus() async throws {
        #expect(try await run("exit 0") == 0)
        #expect(try await run("exit 3") == 3)
    }

    @Test("X-5 an executable outside the allowlist never runs")
    func refusesExecutablesOutsideTheAllowlist() async throws {
        let marker = home.appending(path: "ran")
        let script = try script("touch \"$HOME/ran\"", at: "other")
        let runner = FoundationProcessRunner(allowedExecutables: [home.appending(path: "tool")], home: home, userName: "tester", log: log)
        #expect(await runner.run(script, arguments: []) == nil)
        #expect(!FileManager.default.fileExists(atPath: marker.path(percentEncoded: false)))
    }

    @Test("B-71 a run past its timeout is stopped and exits with a failure")
    func stopsARunPastItsTimeout() async throws {
        let status = try await run("sleep 5", timeout: .milliseconds(200))
        #expect(status != 0)
    }

    @Test("B-63 the process gets a clean environment: home, user and the system path")
    func getsOnlyHomeUserAndSystemPath() async throws {
        _ = try await run(#"env | cut -d= -f1 | sort > "$HOME/environment""#)
        let names = try String(contentsOf: home.appending(path: "environment"), encoding: .utf8)
        // `sh` adds PWD, SHLVL and _ to what it was given.
        #expect(names.split(separator: "\n").filter { !["PWD", "SHLVL", "_"].contains($0) } == ["HOME", "LOGNAME", "PATH", "USER"])
    }

    @Test("B-63 the process runs in a folder without .claude/")
    func runsOutsideAnyClaudeFolder() async throws {
        // The home has one, so running there would load its settings.
        try FileManager.default.createDirectory(at: home.appending(path: ".claude"), withIntermediateDirectories: true)
        _ = try await run(#"pwd -P > "$HOME/folder""#)
        let folder = try String(contentsOf: home.appending(path: "folder"), encoding: .utf8).trimmingCharacters(in: .newlines)
        #expect(!FileManager.default.fileExists(atPath: URL(filePath: folder).appending(path: ".claude").path(percentEncoded: false)))
    }

    @Test("B-63 the process gets exactly its arguments")
    func getsExactlyItsArguments() async throws {
        _ = try await run(#"printf '%s\n' "$@" > "$HOME/arguments""#, arguments: ["-p", "one word", "--tools", ""])
        let arguments = try String(contentsOf: home.appending(path: "arguments"), encoding: .utf8)
        // An empty argument makes an empty line; the last piece is past printf's final newline.
        #expect(Array(arguments.split(separator: "\n", omittingEmptySubsequences: false).dropLast()) == ["-p", "one word", "--tools", ""])
    }

    @Test("B-63 the process reads nothing and its output is discarded")
    func inputAndOutputAreTheNullDevice() async throws {
        // The script fails unless its standard input, output and error are all /dev/null.
        #expect(try await run("[ /dev/fd/0 -ef /dev/null ] && [ /dev/fd/1 -ef /dev/null ] && [ /dev/fd/2 -ef /dev/null ]") == 0)
    }

    @Test("B-64 a run records only its exit status and how long it took")
    func recordsOnlyStatusAndTime() async throws {
        _ = try await run("exit 0")
        let record = try #require(log.records.first)
        #expect(record.event == "process")
        #expect(record.measures.count == 2)
    }

    private func run(_ body: String, arguments: [String] = [], timeout: Duration = .seconds(10)) async throws -> Int32? {
        let executable = try script(body, at: "tool")
        let runner = FoundationProcessRunner(allowedExecutables: [executable], home: home, userName: "tester", timeout: timeout, log: log)
        return await runner.run(executable, arguments: arguments)
    }

    private func script(_ body: String, at path: String) throws -> URL {
        let url = home.appending(path: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "#!/bin/sh\n\(body)\n".write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path(percentEncoded: false))
        return url
    }
}
