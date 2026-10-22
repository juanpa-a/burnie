import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieProviders

struct CursorProviderTests {
    let recorder = ProviderPortsRecorder()

    func bundle() -> ProviderBundle {
        CursorProvider.bundle(CursorPorts(
            clock: FixedClock(now: .iso("2026-10-10T20:00:00Z")),
            database: FakeKeyValueDatabase(),
            log: RecordingDiagnosticsLog(),
            home: URL(filePath: "/Users/dev"),
            userAgent: "Burnie/0.1.0",
            makeHTTPClient: recorder.makeHTTPClient
        ))
    }

    func task(_ kind: PartKind) throws -> RefreshTask {
        try #require(bundle().tasks.first { $0.part == kind })
    }

    // MARK: Descriptor

    @Test("the provider and meter ids are frozen (SPEC 12)")
    func idsAreFrozen() {
        #expect(ProviderID.cursor.rawValue == "cursor")
        #expect([MeterID.cursorModels, .otherModels, .included, .teamPool, .onDemand, .teamOnDemand].map(\.rawValue) == [
            "cursorModels", "otherModels", "included", "teamPool", "onDemand", "teamOnDemand",
        ])
    }

    @Test("B-21 Cursor's issue rows")
    func issueRows() {
        let copy = CursorProvider.descriptor.copy
        #expect(IssueMessage.message(for: .notFound, copy: copy) == "Cursor not found. Sign in to the Cursor app.")
        #expect(IssueMessage.message(for: .signInExpired, copy: copy) == "Session expired. Open Cursor to sign in again.")
        #expect(IssueMessage.message(for: .unexpectedResponse("HTTP 404"), copy: copy) == "Couldn't read usage. Burnie may need an update.")
    }

    @Test("B-29 Cursor's healthy status line reads the plan chip as a name")
    func healthyStatusLine() {
        let status = CursorProvider.descriptor.copy.status
        #expect(status(StatusContext(plan: PlanName(rawValue: "PRO"), sourceLocation: nil)) == "Signed in · Pro plan")
        #expect(status(StatusContext(plan: PlanName(rawValue: "PRO+"), sourceLocation: nil)) == "Signed in · Pro+ plan")
        #expect(status(StatusContext(plan: nil, sourceLocation: nil)) == "Signed in")
    }

    @Test("B-75 Cursor's names, dashboard link, meters and placeholders")
    func namesLinksAndMeters() {
        let descriptor = CursorProvider.descriptor
        #expect(descriptor.displayName == "Cursor")
        #expect(descriptor.shortName == "Cursor")
        #expect(descriptor.dashboard == DashboardLink(title: "Open Cursor dashboard", url: URL(string: "https://cursor.com/dashboard/spending")!))
        #expect(descriptor.meters.map(\.label) == ["Cursor Models", "Other Models", "Included usage", "Team pool", "On-demand", "Team on-demand"])
        #expect(descriptor.placeholderMeters == [.cursorModels, .otherModels])
    }

    @Test("SPEC 5.3 every meter Cursor's mapper produces is declared in its descriptor", arguments: [
        "cursor-summary-pro.json", "cursor-summary-free.json", "cursor-summary-on-demand.json",
        "cursor-summary-team.json", "cursor-summary-enterprise.json", "cursor-summary-unlimited.json",
    ])
    func mappedMetersAreDeclared(fixture: String) throws {
        let limits = try CursorUsageMapper.limits(from: JSONDecoder().decode(CursorUsageSummaryDTO.self, from: Fixture.data(fixture)))
        let declared = Set(CursorProvider.descriptor.meters.map(\.id))
        let produced = limits.meters.all + [limits.features.onDemand].compactMap { $0 }
        #expect(produced.allSatisfy { declared.contains($0.id) })
    }

    // MARK: Bundle

    @Test("B-30 Cursor's limits refresh every 10 min ± 30 s, on open after 60 s, over the network")
    func limitsPolicy() throws {
        let limits = try task(.limits)
        #expect(limits.name == "limits")
        #expect(limits.policy == RefreshPolicy(interval: 600, jitter: 30, staleOnOpen: 60, needsNetwork: true))
    }

    @Test("B-30 Cursor's activity refreshes every 30 min, on open after 10 min, over the network, unwatched")
    func activityPolicy() throws {
        let activity = try task(.activity)
        #expect(activity.name == "activity")
        #expect(activity.policy == RefreshPolicy(interval: 1_800, jitter: 0, staleOnOpen: 600, needsNetwork: true))
        #expect(activity.watcher == nil)
    }

    @Test("B-60 Cursor's HTTP client reaches only cursor.com")
    func httpReachesOnlyCursor() {
        _ = bundle()
        #expect(recorder.requestedHosts == [["cursor.com"]])
    }

    @Test("B-22 Cursor has no capabilities: it can't renew its sign-in and reads no local logs")
    func noCapabilities() {
        let capabilities = bundle().capabilities
        #expect(capabilities.signInRenewal == nil)
        #expect(capabilities.sourceLocation == nil)
    }

    @Test("B-26 without a session, Cursor's tasks are not found and never reach the network", arguments: [PartKind.limits, .activity])
    func tasksWithoutASession(kind: PartKind) async throws {
        #expect(try await task(kind).run() == .failure(.notFound))
        #expect(recorder.http.requests.isEmpty)
    }
}
