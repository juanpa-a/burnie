import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieProviders

struct ClaudeProviderTests {
    static let home = URL(filePath: "/Users/dev")
    let files = InMemoryFiles()
    let recorder = ProviderPortsRecorder()

    func bundle() -> ProviderBundle {
        ClaudeProvider.bundle(ClaudePorts(
            clock: FixedClock(now: .iso("2026-10-10T20:00:00Z")),
            files: files,
            secrets: FakeSecretReader(),
            storage: InMemoryProviderStorage(),
            log: RecordingDiagnosticsLog(),
            home: Self.home,
            userName: "dev",
            userAgent: "Burnie/0.1.0",
            makeHTTPClient: recorder.makeHTTPClient,
            makeWatcher: recorder.makeWatcher,
            makeProcessRunner: recorder.makeProcessRunner
        ))
    }

    func task(_ kind: PartKind) throws -> RefreshTask {
        try #require(bundle().tasks.first { $0.part == kind })
    }

    // MARK: Descriptor

    @Test("the provider and meter ids and the missingScope code are frozen (SPEC 12)")
    func idsAreFrozen() {
        #expect(ProviderID.claude.rawValue == "claude")
        #expect([MeterID.session, .weekly].map(\.rawValue) == ["session", "weekly"])
        #expect(SpecificIssue.missingScope.code == "missingScope")
    }

    @Test("B-21 Claude's issue rows")
    func issueRows() {
        let copy = ClaudeProvider.descriptor.copy
        #expect(IssueMessage.message(for: .notFound, copy: copy) == "Claude Code not found. Install it and sign in.")
        #expect(IssueMessage.message(for: .signInExpired, copy: copy) == "Limits paused. Open Claude Code to refresh sign-in.")
        #expect(IssueMessage.message(for: .specific(.missingScope), copy: copy) == "This sign-in can't read limits. Run `claude` and log in again.")
        #expect(IssueMessage.message(for: .unexpectedResponse("HTTP 404"), copy: copy) == "Couldn't read usage. Burnie may need an update.")
    }

    @Test("B-29 Claude's healthy status line says where it reads the logs")
    func healthyStatusLine() {
        let status = ClaudeProvider.descriptor.copy.status
        #expect(status(StatusContext(plan: nil, sourceLocation: "~/.config/claude")) == "Reading local logs · ~/.config/claude")
        #expect(status(StatusContext(plan: PlanName(rawValue: "MAX"), sourceLocation: nil)) == "Reading local logs · ~/.claude")
    }

    @Test("B-75 Claude's names, dashboard link, meters and placeholders")
    func namesLinksAndMeters() {
        let descriptor = ClaudeProvider.descriptor
        #expect(descriptor.displayName == "Claude Code")
        #expect(descriptor.shortName == "Claude")
        #expect(descriptor.dashboard == DashboardLink(title: "Open Claude usage page", url: URL(string: "https://claude.ai/settings/usage")!))
        #expect(descriptor.meters == [MeterDescriptor(id: .session, label: "Session · 5h"), MeterDescriptor(id: .weekly, label: "Weekly")])
        #expect(descriptor.placeholderMeters == [.session, .weekly])
    }

    @Test("SPEC 5.3 every meter Claude's mapper produces is declared in its descriptor", arguments: [
        "claude-usage-both.json", "claude-usage-flat.json", "claude-usage-limits.json", "claude-usage-no-session.json",
    ])
    func mappedMetersAreDeclared(fixture: String) throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let meters = try ClaudeUsageMapper.meters(from: decoder.decode(ClaudeUsageDTO.self, from: Fixture.data(fixture)))
        let declared = Set(ClaudeProvider.descriptor.meters.map(\.id))
        #expect(meters.all.allSatisfy { declared.contains($0.id) })
    }

    // MARK: Bundle

    @Test("B-30 Claude's limits refresh every 5 min ± 30 s, on open after 60 s, over the network")
    func limitsPolicy() throws {
        let limits = try task(.limits)
        #expect(limits.name == "limits")
        #expect(limits.policy == RefreshPolicy(interval: 300, jitter: 30, staleOnOpen: 60, needsNetwork: true))
        #expect(limits.watcher == nil)
    }

    @Test("B-30 Claude's activity refreshes every 5 min, never on open, without the network")
    func activityPolicy() throws {
        let activity = try task(.activity)
        #expect(activity.name == "activity")
        #expect(activity.policy == RefreshPolicy(interval: 300, jitter: 0, staleOnOpen: nil, needsNetwork: false))
    }

    @Test("B-72 Claude's activity is watched over both log roots")
    func activityIsWatchedOverTheLogRoots() throws {
        #expect(try task(.activity).watcher != nil)
        #expect(recorder.watchedDirectories == [ClaudePaths(home: Self.home).logRoots])
    }

    @Test("B-60 Claude's HTTP client reaches only api.anthropic.com")
    func httpReachesOnlyAnthropic() {
        _ = bundle()
        #expect(recorder.requestedHosts == [["api.anthropic.com"]])
    }

    @Test("B-27 Claude's limits task reads its part through the ports, and fails with its issue")
    func limitsTaskRunsThroughThePorts() async throws {
        #expect(try await task(.limits).run() == .failure(.notFound))
    }

    @Test("B-45 without any log root Claude's activity task is not found, and its location is the default")
    func activityTaskWithoutLogs() async throws {
        #expect(try await task(.activity).run() == .failure(.notFound))
        #expect(bundle().capabilities.sourceLocation == "~/.claude")
    }

    // MARK: Sign-in renewal

    @Test("B-22 without an installed claude, Claude can't renew its sign-in")
    func noRenewalWithoutClaude() {
        #expect(bundle().capabilities.signInRenewal == nil)
    }

    @Test("B-61 B-63 the renewal runs the first installed claude, with fixed arguments, from an allowlist of the candidates")
    func renewalRunsTheInstalledClaude() async throws {
        let homebrew = URL(filePath: "/opt/homebrew/bin/claude")
        files.installExecutable(homebrew)
        let renewal = try #require(bundle().capabilities.signInRenewal)

        #expect(await renewal.run())
        #expect(recorder.runner.runs == [FakeProcessRunner.Run(executable: homebrew, arguments: [
            "-p", "Reply with the single word: ok",
            "--model", "haiku",
            "--tools", "",
            "--no-session-persistence",
            "--setting-sources", "project",
        ])])
        #expect(recorder.allowedExecutables == [ClaudeSignInRenewal.candidates(home: Self.home)])
    }

    @Test("B-63 the native installer's claude comes before Homebrew's")
    func candidatesKeepTheirOrder() {
        #expect(ClaudeSignInRenewal.candidates(home: Self.home).map(\.path) == [
            "/Users/dev/.local/bin/claude", "/opt/homebrew/bin/claude", "/usr/local/bin/claude",
        ])
    }

    @Test("B-22 B-71 a renewal that exits with a failure, or can't start, failed, and says how to sign in by hand", arguments: [Int32(1), 15, nil])
    func failedRenewal(status: Int32?) async throws {
        files.installExecutable(URL(filePath: "/usr/local/bin/claude"))
        recorder.runner.exit(with: status)
        let renewal = try #require(bundle().capabilities.signInRenewal)
        #expect(await renewal.run() == false)
        #expect(renewal.failedCopy == "Couldn't refresh sign-in. Run `claude` in Terminal and log in again.")
    }
}
