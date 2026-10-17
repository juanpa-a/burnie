import Foundation
import os
import Testing
@testable import BurnieSystem

final class ClaudeCodeSignInRenewerTests {
    let home = FileManager.default.temporaryDirectory.appending(path: "burnie-renewer-\(UUID().uuidString)")

    deinit {
        try? FileManager.default.removeItem(at: home)
    }

    @Test func succeedsWhenClaudeExitsCleanly() async throws {
        try await renewer(running: "exit 0").renewSignIn()
    }

    @Test func failsWithClaudesExitStatus() async throws {
        await #expect(throws: ClaudeCodeSignInRenewer.Failure.self) {
            try await renewer(running: "exit 3").renewSignIn()
        }
    }

    @Test("B-71 a renewal that runs past its timeout is stopped and counts as failed")
    func givesUpWhenClaudeHangs() async throws {
        await #expect(throws: ClaudeCodeSignInRenewer.Failure.self) {
            try await renewer(running: "sleep 5", timeout: .milliseconds(200)).renewSignIn()
        }
    }

    @Test("B-63 the renewal gets a clean environment: home, user and the system path")
    func claudeGetsOnlyHomeUserAndSystemPath() async throws {
        try await renewer(running: #"env | cut -d= -f1 | sort > "$HOME/environment""#).renewSignIn()
        let names = try String(contentsOf: home.appending(path: "environment"), encoding: .utf8)
        // `sh` adds PWD, SHLVL and _ to what it was given.
        #expect(names.split(separator: "\n").filter { !["PWD", "SHLVL", "_"].contains($0) } == ["HOME", "LOGNAME", "PATH", "USER"])
    }

    @Test("B-63 the renewal runs in a folder without .claude/")
    func claudeRunsOutsideAnyClaudeFolder() async throws {
        // The home has one, so running there would load its settings.
        try FileManager.default.createDirectory(at: home.appending(path: ".claude"), withIntermediateDirectories: true)
        try await renewer(running: #"pwd -P > "$HOME/folder""#).renewSignIn()
        let folder = try String(contentsOf: home.appending(path: "folder"), encoding: .utf8).trimmingCharacters(in: .newlines)
        #expect(!FileManager.default.fileExists(atPath: URL(filePath: folder).appending(path: ".claude").path(percentEncoded: false)))
    }

    @Test("B-63 the renewal asks for one word with no tools, no user settings and no session persistence")
    func claudeGetsOnlyTheFixedArguments() async throws {
        try await renewer(running: #"printf '%s\n' "$@" > "$HOME/arguments""#).renewSignIn()
        let arguments = try String(contentsOf: home.appending(path: "arguments"), encoding: .utf8)
        // `--tools` gets an empty argument, so empty lines count; the last piece is past printf's final newline.
        #expect(Array(arguments.split(separator: "\n", omittingEmptySubsequences: false).dropLast()) == [
            "-p", "Reply with the single word: ok",
            "--model", "haiku",
            "--tools", "",
            "--no-session-persistence",
            "--setting-sources", "project",
        ])
    }

    @Test("B-63 the renewal reads nothing and its output is discarded")
    func claudesInputAndOutputAreTheNullDevice() async throws {
        // The script fails unless its standard input, output and error are all /dev/null.
        try await renewer(running: "[ /dev/fd/0 -ef /dev/null ] && [ /dev/fd/1 -ef /dev/null ] && [ /dev/fd/2 -ef /dev/null ]").renewSignIn()
    }

    @Test func findsTheNativeInstallInHome() throws {
        let claude = try script("exit 0", at: ".local/bin/claude")
        #expect(ClaudeCodeSignInRenewer.installed(home: home, userName: "tester", logger: Self.logger)?.executable == claude)
    }

    private static let logger = Logger(subsystem: "dev.juanpa.burnie.tests", category: "renewer")

    private func renewer(running body: String, timeout: Duration = .seconds(10)) throws -> ClaudeCodeSignInRenewer {
        ClaudeCodeSignInRenewer(executable: try script(body, at: "claude"), home: home, userName: "tester", timeout: timeout, logger: Self.logger)
    }

    private func script(_ body: String, at path: String) throws -> URL {
        let url = home.appending(path: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "#!/bin/sh\n\(body)\n".write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path(percentEncoded: false))
        return url
    }
}
