import BurnieInterface
import Foundation

/// `ProcessRunner` over `Process`: only the executables of its allowlist, with a minimal environment, from a folder
/// without `.claude/`, no input or output, and stopped after its timeout (B-63, B-71, X-5).
public struct FoundationProcessRunner: ProcessRunner {
    private let allowedExecutables: Set<URL>
    private let home: URL
    private let userName: String
    private let timeout: Duration
    private let log: any DiagnosticsLog

    public init(allowedExecutables: [URL], home: URL, userName: String, timeout: Duration = .seconds(60), log: any DiagnosticsLog) {
        self.allowedExecutables = Set(allowedExecutables)
        self.home = home
        self.userName = userName
        self.timeout = timeout
        self.log = log
    }

    public func run(_ executable: URL, arguments: [String]) async -> Int32? {
        guard allowedExecutables.contains(executable) else { return nil }
        let started = ContinuousClock.now
        guard let status = try? await exitStatus(of: process(executable, arguments: arguments)) else { return nil }
        log.record("process", [.status(Int(status)), .seconds("elapsed", (ContinuousClock.now - started) / .seconds(1))])
        return status
    }

    /// Its output is discarded: it can carry account details, and the exit status says enough.
    private func process(_ executable: URL, arguments: [String]) -> Process {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        // Only what a provider's app needs to find its sign-in: nothing from Burnie's environment reaches it.
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
        return process
    }

    /// Runs `process` to its end, stopping it once the timeout passes, which ends it with a failure status.
    private func exitStatus(of process: Process) async throws -> Int32 {
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
