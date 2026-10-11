import Foundation
import BurnieCore

/// Reads Keychain items with `/usr/bin/security`, the same binary Claude Code writes its item with:
/// that way no access prompt appears and reading survives Burnie rebuilds.
public struct SecurityCLIKeychain: SecretReader {
    /// `security`'s exit code when the item doesn't exist.
    private static let itemNotFound: Int32 = 44
    private static let executable = URL(filePath: "/usr/bin/security")

    public enum Failure: Error {
        case exitStatus(Int32)
    }

    public init() {}

    public func genericPassword(service: String, account: String?) throws -> Data? {
        let process = Process()
        process.executableURL = Self.executable
        var arguments = ["find-generic-password", "-s", service]
        if let account {
            arguments += ["-a", account]
        }
        process.arguments = arguments + ["-w"]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        try process.run()
        // Read before waiting: if the output filled the pipe, `security` would block.
        let password = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        switch process.terminationStatus {
        case 0: return password.trimmingTrailingNewline()
        case Self.itemNotFound: return nil
        case let status: throw Failure.exitStatus(status)
        }
    }
}

private extension Data {
    func trimmingTrailingNewline() -> Data {
        last == UInt8(ascii: "\n") ? dropLast() : self
    }
}
