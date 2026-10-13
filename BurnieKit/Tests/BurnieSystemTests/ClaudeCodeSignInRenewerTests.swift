import Foundation
import os
import Testing
@testable import BurnieSystem

struct ClaudeCodeSignInRenewerTests {
    let home = FileManager.default.temporaryDirectory.appending(path: "burnie-renewer-\(UUID().uuidString)")

    @Test func succeedsWhenClaudeExitsCleanly() async throws {
        try await renewer(running: "exit 0").renewSignIn()
    }

    @Test func failsWithClaudesExitStatus() async throws {
        await #expect(throws: ClaudeCodeSignInRenewer.Failure.self) {
            try await renewer(running: "exit 3").renewSignIn()
        }
    }

    @Test func givesUpWhenClaudeHangs() async throws {
        await #expect(throws: ClaudeCodeSignInRenewer.Failure.self) {
            try await renewer(running: "sleep 5", timeout: .milliseconds(200)).renewSignIn()
        }
    }

    @Test func claudeGetsOnlyHomeUserAndSystemPath() async throws {
        try await renewer(running: #"env | cut -d= -f1 | sort > "$HOME/environment""#).renewSignIn()
        let names = try String(contentsOf: home.appending(path: "environment"), encoding: .utf8)
        // `sh` adds PWD, SHLVL and _ to what it was given.
        #expect(names.split(separator: "\n").filter { !["PWD", "SHLVL", "_"].contains($0) } == ["HOME", "LOGNAME", "PATH", "USER"])
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
