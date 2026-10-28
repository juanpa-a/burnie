import BurnieApplication
import BurnieInfra
import BurnieInterface
import BurnieProviders
import Foundation

/// The single place that builds the adapters, the provider bundles and the app model, in that order, and connects
/// them (V-3). Each provider gets its storage and its log bound to its id, so the adapters its factories build log
/// through it too.
@MainActor
enum CompositionRoot {
    static func makeModel() -> AppModel {
        let appLog = OSDiagnosticsLog(category: "app")
        let store = fileStore(log: appLog)
        let clock = SystemClock()
        let home = FileManager.default.homeDirectoryForCurrentUser
        let userName = NSUserName()
        let userAgent = "Burnie/\(appVersion)"

        let claudeLog = OSDiagnosticsLog(category: ClaudeProvider.descriptor.id.rawValue)
        let claude = ClaudeProvider.bundle(ClaudePorts(
            clock: clock,
            files: LocalFileReader(),
            secrets: SecurityCLIKeychain(),
            storage: store.storage(for: ClaudeProvider.descriptor.id),
            log: claudeLog,
            home: home,
            userName: userName,
            userAgent: userAgent,
            makeHTTPClient: { URLSessionHTTPClient(allowedHosts: $0, log: claudeLog) },
            makeWatcher: { DirectoryWatcher(directories: $0) },
            makeProcessRunner: { FoundationProcessRunner(allowedExecutables: $0, home: home, userName: userName, log: claudeLog) }
        ))

        let cursorLog = OSDiagnosticsLog(category: CursorProvider.descriptor.id.rawValue)
        let cursor = CursorProvider.bundle(CursorPorts(
            clock: clock,
            database: SQLiteKeyValueReader(),
            // The Cursor app made its item, so reading it asks the user: from Burnie's own process, Always Allow grants
            // Burnie alone, not `/usr/bin/security`.
            secrets: SecurityFrameworkKeychain(),
            decryptor: CommonCryptoSafeStorageDecryptor(),
            log: cursorLog,
            home: home,
            userAgent: userAgent,
            makeHTTPClient: { URLSessionHTTPClient(allowedHosts: $0, log: cursorLog) }
        ))

        return AppModel.live(AppEnvironment(
            clock: clock,
            sleeper: TaskSleeper(),
            snapshotCache: store,
            settingsStore: UserDefaultsSettingsStore(),
            systemEvents: MacSystemEvents(),
            loginItem: SMAppLoginItem(),
            updater: SparkleUpdater(),
            urlOpener: WorkspaceURLOpener(),
            lifecycle: NSAppLifecycle(),
            providers: [claude, cursor]
        ))
    }

    /// `Application Support/Burnie/`, or a temporary folder when it isn't usable, so the app still runs (B-73).
    private static func fileStore(log: any DiagnosticsLog) -> JSONFileStore {
        do {
            return try JSONFileStore.applicationSupport()
        } catch {
            log.record("noApplicationSupport", [])
            return JSONFileStore(directory: FileManager.default.temporaryDirectory.appending(path: "Burnie"))
        }
    }

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }
}
