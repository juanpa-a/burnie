import Foundation
import os
import BurnieCore

/// Claude Code: limits via OAuth and tokens from the local logs.
public enum ClaudeProvider {
    public static func assemble(in environment: ProviderEnvironment) -> ProviderAssembly {
        let paths = ClaudePaths(home: environment.home)
        let logger = Logger(subsystem: "dev.juanpa.burnie", category: "claude")
        let files = LocalFileReader()
        let limits = ClaudeLimitsFetcher(
            credentials: ClaudeCredentialsReader(secrets: SecurityCLIKeychain(), files: files, paths: paths, account: environment.userName),
            http: URLSessionHTTPClient(allowedHosts: ["api.anthropic.com"], logger: logger),
            clock: environment.clock,
            userAgent: environment.userAgent
        )
        let activity = ClaudeLogActivity(roots: paths.logRoots, files: files, store: environment.store, clock: environment.clock) { report in
            logger.info("Log scan: \(report.filesRead) files, \(report.bytesRead) bytes, \(report.countedLines) counted, \(report.duplicateLines) duplicates, \(report.unreadableLines) unreadable lines, \(report.unreadableFiles) unreadable files")
        }
        let existingRoot = paths.logRoots.first { FileManager.default.fileExists(atPath: $0.path(percentEncoded: false)) }
        return ProviderAssembly(
            provider: CompositeUsageProvider(id: .claude, limits: limits, activity: activity, clock: environment.clock),
            watcher: ClaudeLogDirectoryWatcher(roots: paths.logRoots),
            sourceLocation: paths.displayName(ofLogRoot: existingRoot ?? paths.defaultLogRoot)
        )
    }
}
