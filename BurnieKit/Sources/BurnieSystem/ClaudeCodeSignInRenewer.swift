import Foundation
import os
import BurnieCore

/// Renews Claude Code's sign-in by running Claude Code itself: a one-word Haiku reply needs a valid token,
/// so `claude` refreshes and saves its own. Burnie never sees the refresh token or writes the Keychain item.
public struct ClaudeCodeSignInRenewer: SignInRenewer {
    public enum Failure: Error {
        case exitStatus(Int32)
    }

    /// No tools, no user settings (nor their hooks), no saved session: only what makes Claude Code need its token.
    private static let arguments = [
        "-p", "Reply with the single word: ok",
        "--model", "haiku",
        "--tools", "",
        "--no-session-persistence",
        "--setting-sources", "project",
    ]

    let executable: URL
    private let home: URL
    private let userName: String
    private let timeout: Duration
    private let logger: Logger

    init(executable: URL, home: URL, userName: String, timeout: Duration = .seconds(60), logger: Logger) {
        self.executable = executable
        self.home = home
        self.userName = userName
        self.timeout = timeout
        self.logger = logger
    }

    /// The `claude` that Claude Code's installers leave, or nil if there's none to ask.
    public static func installed(home: URL, userName: String, logger: Logger) -> ClaudeCodeSignInRenewer? {
        let candidates = [
            home.appending(path: ".local/bin/claude"), // native installer
            URL(filePath: "/opt/homebrew/bin/claude"), // Homebrew on Apple silicon
            URL(filePath: "/usr/local/bin/claude"), // Homebrew on Intel, npm
        ]
        return candidates
            .first { FileManager.default.isExecutableFile(atPath: $0.path(percentEncoded: false)) }
            .map { ClaudeCodeSignInRenewer(executable: $0, home: home, userName: userName, logger: logger) }
    }

    public func renewSignIn() async throws {
        let started = ContinuousClock.now
        let status = try await runClaude()
        let elapsed = ContinuousClock.now - started
        logger.info("Sign-in renewal: exit \(status), \(elapsed.components.seconds) s")
        guard status == 0 else { throw Failure.exitStatus(status) }
    }

    /// Its output is discarded: it can carry account details, and the exit status says enough.
    private func runClaude() async throws -> Int32 {
        let process = Process()
        process.executableURL = executable
        process.arguments = Self.arguments
        // Only what Claude Code needs to find its sign-in: nothing from Burnie's environment reaches it.
        process.environment = [
            "HOME": home.path(percentEncoded: false),
            "USER": userName,
            "LOGNAME": userName,
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
        ]
        // A folder without `.claude/`, so no project settings load either.
        process.currentDirectoryURL = FileManager.default.temporaryDirectory
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        let deadline = Task { [timeout] in
            try await Task.sleep(for: timeout)
            process.terminate()
        }
        defer { deadline.cancel() }
        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { continuation.resume(returning: $0.terminationStatus) }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
