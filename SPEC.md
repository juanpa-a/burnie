# Burnie architecture spec

The target architecture for Burnie's refactor, the internal language it is written in, the behavior it must keep,
the migration that gets there, and how every step is verified.

- **Status:** agreed design, implementation not started. Section 13 records every decision; all are agreed. The open
  questions in section 18 are verified during implementation, not before.
- **Audience:** humans and agents. Every rule has an ID (`D-3`, `A-7`…) so that reviews, commit messages and the
  architecture check can point at it.
- **Precedence:** during the refactor this file wins over the module `AGENTS.md` files for anything about layers,
  names and verification. The root `AGENTS.md` rules (cleanliness first, no sensitive data, read-only over other apps)
  stay in force and are never relaxed by this spec.
- **Changing this spec:** a change to a rule or a decision is its own PR that edits this file first. Code never
  "works around" the spec: if something doesn't fit, stop and escalate (rule `G-1`).

## Contents

1. [Principles](#1-principles)
2. [Glossary](#2-glossary)
3. [Architecture](#3-architecture)
4. [Domain](#4-domain-burniedomain)
5. [Interface](#5-interface-burnieinterface)
6. [Providers](#6-providers-burnieproviders)
7. [Application](#7-application-burnieapplication)
8. [Infra](#8-infra-burnieinfra)
9. [Components](#9-components-burniecomponents)
10. [App](#10-app-target)
11. [Behavior catalog](#11-behavior-catalog)
12. [Persistence contract](#12-persistence-contract)
13. [Decision log](#13-decision-log)
14. [Delivery plan](#14-delivery-plan)
15. [File inventory](#15-file-inventory)
16. [Verification and quality control](#16-verification-and-quality-control)
17. [How agents discover the rules](#17-how-agents-discover-the-rules)
18. [Open questions](#18-open-questions)

---

## 1. Principles

These are the reasons behind every rule below. When a rule is unclear, the principle decides.

1. **One internal language.** Every concept the system talks about has one name, defined in the glossary
   (section 2) and modeled as a type in `BurnieDomain`. Code, comments, tests, PRs and the UI copy keys use that name.
   No synonyms: a "meter" is never a "bar", "gauge" or "limit" in code.
2. **Pure core, effects at the edge.** `BurnieDomain`, `BurnieInterface` and the pure parts of the other modules
   are values and total functions. Time, disk, network, Keychain, processes and the OS only happen behind ports
   (section 5.2), implemented in `BurnieInfra` and wired in the composition root.
3. **Algebraic data types first.** State is modeled with structs (products) and enums with payloads (sums) so that
   invalid states can't be built. Prefer a non-empty type to a runtime check, an enum to a flag pair,
   a newtype to a bare `Int`.
4. **Laws are tests.** When an operation has an algebraic shape (merge, combine, toggle, clamp, advance), its laws
   are written down here and checked with property tests (section 16.4).
5. **The compiler is the first reviewer.** Layers are SwiftPM modules, so a forbidden import doesn't compile.
   Registries are closed types, so a missing branch doesn't compile. What the compiler can't check, the
   architecture script checks (section 16.2); what the script can't check, the review checklist does (section 16.8).
6. **Capabilities are optional data.** What a provider can do and what a snapshot carries are optional fields of
   closed structs declared in `BurnieInterface`. The UI handles them with `if let`. No protocol casts, no `as?`.
7. **One owner of state.** Only `BurnieApplication` holds the state that changes over time. Everything else
   computes, reads or performs on request.
8. **Small, named, single-purpose.** One type per file, small functions, names from the glossary, no dead code,
   no stray TODOs, no duplication between providers. Clean beats done.

---

## 2. Glossary

The internal language. Each term lists its definition, its type and the module that owns it.
A term that isn't here doesn't exist yet: adding one is a spec change (`G-2`).

### 2.1 Providers

| Term | Definition | Type | Module |
| --- | --- | --- | --- |
| **Provider** | A coding tool whose usage Burnie shows: Claude Code, Cursor. | — (a concept; assembled as a `ProviderBundle`) | Providers |
| **Provider ID** | The stable key of a provider, used in settings and file names (`"claude"`, `"cursor"`). Not an enum: no code outside a provider can switch on it. | `ProviderID` (newtype over `String`) | Domain |
| **Provider descriptor** | Everything static the rest of the app needs to know about a provider: names, links, color, meter catalog, copy for its issues, status line. Filled once by each provider. | `ProviderDescriptor` | Interface |
| **Provider bundle** | What a provider hands to the composition root: its descriptor, its capabilities, its refresh tasks. | `ProviderBundle` | Interface |
| **Provider registry** | The ordered list of bundles the app runs. Order is display order. | `[ProviderBundle]` | Composition root |
| **Enabled** | Whether the user tracks a provider. Turning one off deletes nothing. | `Set<ProviderID>` in settings | Domain |
| **Meter descriptor** | A meter kind as its provider declares it: id and label, in display order. | `MeterDescriptor` | Interface |
| **Provider copy** | The provider's own user-visible text: not found, sign-in expired, renewal failed, its specific issues, and its healthy status line. | `ProviderCopy` | Interface |
| **Status context** | What the healthy status line is built from: the plan, if known, and the source location, if any. | `StatusContext` | Interface |
| **Link** | A title and a URL, for the footer's dashboard item. | `Link` | Interface |
| **Color pair** | A provider's accent as light and dark RGB values (`RGB`: red, green, blue in 0…1); Components turns it into a `Color`. | `ColorPair`, `RGB` | Interface |
| **Sign-in renewal** | A capability: a closure the provider builds that runs its own app to renew the sign-in and reports whether it worked. | `SignInRenewal` | Interface |

### 2.2 Usage

| Term | Definition | Type | Module |
| --- | --- | --- | --- |
| **Meter** | One measured limit with a fill between 0 and 1, a value, a caption and an optional period. | `Meter` | Domain |
| **Meter ID** | Stable key of a meter kind (`"session"`, `"cursorModels"`). Declared by its provider. | `MeterID` (newtype over `String`) | Domain |
| **Meter set** | The meters of one snapshot, non-empty by construction, with a **primary meter** first. | `MeterSet` | Domain |
| **Primary meter** | The meter that represents a provider at a glance; the menu bar ring follows it. | `MeterSet.primary` | Domain |
| **Fraction** | A number clamped to 0…1. NaN becomes 0. | `Fraction` | Domain |
| **Tokens** | A count of model tokens. | `Tokens` (newtype over `Int`) | Domain |
| **Cents** | An amount of money in US cents. | `Cents` (newtype over `Int`) | Domain |
| **Meter value** | What a meter reads: a percent, or money used against an optional limit. | `MeterValue` | Domain |
| **Meter caption** | What the line under a meter means: resets in, resets at, cycle ends, no active session, on-demand idle. | `MeterCaption` | Domain |
| **Period** | The window a meter fills over, from its start to its reset. | `DateInterval?` on `Meter` | Domain |
| **Pace** | Where the fill would be at an even rate through the period. | `Meter.elapsedFraction(at:)` | Domain |
| **Over pace** | The part of the fill past the pace. | derived | Domain |
| **Plan** | The name of the user's subscription as a chip shows it (`"MAX"`, `"PRO+"`). | `PlanName` (newtype over `String`) | Domain |
| **Usage unit** | How a plan measures usage: tokens (percentage windows) or money (dollar budget). | `UsageUnit` | Domain |
| **Today's usage** | What the section header shows for today: tokens or money. | `TodayUsage` | Domain |
| **On-demand** | Spend past the included usage, when the plan has it on. A *feature* of a snapshot. | `SnapshotFeatures.onDemand: Meter?` | Domain |

### 2.3 Reading and composing

| Term | Definition | Type | Module |
| --- | --- | --- | --- |
| **Part** | One piece of information a provider reports, with its data: a limits part or an activity part. *How* and *where* a provider gets it is its own business. | `Part` (`.limits(LimitsPart)` / `.activity(ActivityPart)`) | Domain |
| **Part kind** | Which of the two parts a refresh task yields, without the data. | `PartKind` (`.limits` / `.activity`) | Domain |
| **Provider parts** | The latest limits and the latest activity of one provider, each optional until it first arrives. | `ProviderParts` (`Latest<LimitsPart>?`, `Latest<ActivityPart>?`) | Application |
| **Limits part** | Plan, meter set, usage unit and features, as of one moment. | `LimitsPart` | Domain |
| **Activity part** | Tokens per local day and, when the provider can add it up exactly, cents per local day. | `ActivityPart` | Domain |
| **Outcome** | The result of one refresh task: a part, or an issue. | `Result<Part, ProviderIssue>` | Domain |
| **Stamped** | A value and the moment it arrived. | `Stamped<Value>` | Domain |
| **Latest** | The most recent outcome of a part kind: a stamped success, or a failure with its moment and the last stamped success, if any. A sum type: a success never lacks its own stamp. | `Latest<Value>` | Domain |
| **Snapshot** | What the UI shows for a provider: its content, features and a partial issue. | `UsageSnapshot` | Domain |
| **Snapshot content** | What a snapshot is made of: a stamped limits view with today's usage if known, or a stamped today's usage alone. A sum type: a snapshot with neither can't be built, and `fetchedAt` is the stamp of whichever case it is. | `SnapshotContent` | Domain |
| **Limits view** | What limits contribute to a snapshot: plan and meter set. Travels with its stamp as one value, which is what merge keeps. | `LimitsView` | Domain |
| **Compose** | Pure function from the latest limits and activity to a snapshot or an issue. | `UsageSnapshot.compose(…)` | Domain |
| **Merge** | Pure function that keeps what a new snapshot lacks from the previous one ("stale data beats a gap"). | `UsageSnapshot.merge(_:_:)` | Domain |
| **Provider state** | Loading (no data yet), ready (a snapshot, maybe with a partial issue) or failed (nothing to show). | `ProviderState` | Domain |
| **Stale** | A snapshot older than 30 minutes; the UI dims its values. | `UsageSnapshot.isStale(at:)` | Domain |

### 2.4 Issues

| Term | Definition | Type | Module |
| --- | --- | --- | --- |
| **Issue** | Why a provider can't show something. Common cases are shared; a provider adds its own as `specific`. | `ProviderIssue` | Domain |
| **Common issue** | `notFound`, `signInExpired`, `rateLimited(retryAt:)`, `offline`, `unexpectedResponse(String)`. | `ProviderIssue` cases | Domain |
| **Specific issue** | An issue only one provider has (Claude's missing `user:profile` scope). Identified by a code; its copy lives in the provider's descriptor. | `ProviderIssue.specific(SpecificIssue)` | Domain |
| **Partial issue** | An issue shown inside a section that still has data. | `UsageSnapshot.issue` | Domain |
| **Total failure** | An issue with nothing to show: the section shows only the issue row. | `ProviderState.failed` | Domain |

### 2.5 Time and history

| Term | Definition | Type | Module |
| --- | --- | --- | --- |
| **Local day** | A calendar day in the system time zone (`"2026-10-10"`). | `LocalDay` | Domain |
| **Activity window** | The days each activity refresh recomputes: today and the 7 before (8 days). | `ActivityWindow` | Domain |
| **History** | Tokens per day and provider, kept for 35 days. Days inside the window are rewritten; older ones are frozen. | `UsageHistory` | Domain |
| **Retention** | How long history keeps a day: 35 days. | `UsageHistory.retentionDays` | Domain |
| **Daily point** | One day and its tokens. | `DailyPoint` | Domain |
| **Week chart** | The last 7 days of history for the enabled providers, on one shared scale. | `WeekChart` | Domain |
| **Clock** | The only source of `now` and the time zone. | `Clock` port | Interface |

### 2.6 Refresh

| Term | Definition | Type | Module |
| --- | --- | --- | --- |
| **Refresh task** | One opaque job a provider declares: it yields one part and has its own policy. The runtime schedules it without knowing what it reads. | `RefreshTask` | Interface |
| **Refresh policy** | A task's interval, jitter, staleness on popover open, and whether it needs the network. | `RefreshPolicy` | Domain |
| **Trigger** | Why a refresh is requested: timer, popover opened, manual, wake, network restored, activity changed. | `RefreshTrigger` | Domain |
| **Backoff** | The wait after a 429: `Retry-After`, or 1, 2, 4… minutes up to 60. | `RateLimitBackoff` | Domain |
| **Activity watcher** | Something that reports when local activity changes (FSEvents over Claude's logs). | `ActivityWatcher` port | Interface |
| **Job** | One refresh task of one enabled provider as the runtime tracks it: its policy, whether it's running, when it last ran, and its backoff. | `JobKey`, `JobState` in `RuntimeState.jobs` | Application |
| **Single flight** | At most one run of a job at a time. | `JobState.isRunning` | Application |
| **Scheduling** | The pure decisions over a job: whether a trigger runs it now, and how long until its next timer. | `Scheduling.canRun`, `Scheduling.delay` | Application |

### 2.7 App features

| Term | Definition | Type | Module |
| --- | --- | --- | --- |
| **Favorite** | The provider the user marked with the heart. Stored only when marked; at most one. | `ProviderID?` in settings | Domain |
| **Effective favorite** | The stored favorite if it's enabled, else the only enabled provider, else none. Never stored. | `Favorite.effective` | Domain |
| **Ring** | The menu bar icon's ring: the effective favorite's primary meter, in whole percents. Hidden when off, no favorite or no meters. | `RingState` | Domain |
| **Feature toggle** | A user switch that hides a snapshot feature (today: on-demand). Shown only when some enabled snapshot has the feature. | `FeatureToggle` | Domain |
| **Settings** | What the app remembers between launches: enabled, favorite, ring shown, week chart shown, feature toggles. | `AppSettings` | Domain |
| **Launch at login** | Whether macOS opens Burnie at login. Owned by macOS, read on demand. | `LoginItem` port | Interface |
| **Update** | A newer Burnie on the release feed. | `availableUpdate: String?` | Interface |

### 2.8 Architecture terms

| Term | Definition | Where |
| --- | --- | --- |
| **Capability** | Something a provider *can do*, fixed when it's assembled (renew sign-in, has a source location). Optional field of `ProviderCapabilities`. | Interface |
| **Feature** | Something a snapshot *carries*, which may change with the plan (on-demand meter). Optional field of `SnapshotFeatures`. | Domain |
| **Port** | A protocol for an effect the core needs (clock, HTTP, files, Keychain…). | Interface |
| **Adapter** | The macOS implementation of a port. Dumb: no business rules. | Infra |
| **Use case** | One thing the user can do, as the UI calls it. A struct of one closure. | Interface |
| **Use cases** | All the use cases together, one field each, so previews and tests replace them with no-ops or recorders. | Interface (`UseCases`) |
| **App state** | The pure value the views render. | Interface |
| **Provider panel** | One provider as the views see it: descriptor, enabled, effective favorite, its state after feature toggles, and its capabilities flattened. | Interface (`ProviderPanel`) |
| **HTTP request** | The value a provider hands the HTTP port: method, URL, headers, body. Never a `URLRequest`. | Interface (`HTTPRequest`) |
| **App environment** | What the composition root hands Application: every port and the provider bundles. | Application (`AppEnvironment`) |
| **App model** | The observable holder of the app state and the use cases; the only Application type the views see. | Application |
| **Event** | Something that happened that may change state. | Application |
| **Effect** | Something the reducer asks the runtime to perform. | Application |
| **Reducer** | Pure function `(State, Event) -> (State, [Effect])`. | Application |
| **Composition root** | The single place that builds adapters, providers and the app model, and connects them. | App target |
| **Component** | A SwiftUI view that takes values and closures and knows nothing about the app model. | Components |
| **View** | A SwiftUI view that reads the app model and wires components to use cases. | App target |
| **Copy** | Every user-visible string. | Interface (`Presentation/`) |

---

## 3. Architecture

### 3.1 Modules

One SwiftPM module per layer (agreed), all with the `Burnie` prefix (agreed), inside `BurnieKit`,
plus the Xcode app target.

```
                    ┌───────────────────────────────┐
                    │ App target                    │
                    │ views · composition root      │
                    └──┬──────────┬──────────┬──────┘
                       │          │          │ (composition root only)
          ┌────────────▼───┐  ┌───▼──────────────┐  ┌──────────────┐  ┌────────────┐
          │ BurnieComponents│  │ BurnieApplication│  │BurnieProviders│  │ BurnieInfra│
          │ SwiftUI pieces  │  │ state · scheduler│  │ Claude ·Cursor│  │ adapters   │
          └───────┬─────────┘  └───┬──────────────┘  └──────┬────────┘  └─────┬──────┘
                  │                │                        │                 │
          ┌───────▼────────────────▼────────────────────────▼─────────────────▼──────┐
          │ BurnieInterface: use cases · app state · ports · capabilities · copy      │
          └───────────────────────────────────┬──────────────────────────────────────┘
                                              │
          ┌───────────────────────────────────▼──────────────────────────────────────┐
          │ BurnieDomain: the internal language, pure                                │
          └──────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Allowed dependencies

Dependencies go one way. The table is the whole truth; `Package.swift` and `project.yml` must match it exactly (`G-3`).

| Module | May import | Never imports |
| --- | --- | --- |
| `BurnieDomain` | `Foundation` | everything else |
| `BurnieInterface` | `Foundation`, `BurnieDomain` | `Observation`, SwiftUI, AppKit, any Burnie module above |
| `BurnieProviders` | `Foundation`, `BurnieDomain`, `BurnieInterface` | `os`, AppKit, SwiftUI, `Application`, `Infra` |
| `BurnieApplication` | `Foundation`, `Observation`, `BurnieDomain`, `BurnieInterface` | `Providers`, `Infra`, SwiftUI, AppKit |
| `BurnieInfra` | `Foundation`, `os`, `AppKit`, `CoreServices`, `Network`, `ServiceManagement`, `SQLite3`, `Sparkle`, `BurnieDomain`, `BurnieInterface` | `Providers`, `Application`, `Components`, SwiftUI |
| `BurnieComponents` | `SwiftUI`, `BurnieDomain`, `BurnieInterface` | `Application`, `Providers`, `Infra`, AppKit |
| App target, views | `SwiftUI`, `AppKit`, `BurnieDomain`, `BurnieInterface`, `BurnieComponents`, `BurnieApplication` (only `AppModel`) | `Providers`, `Infra` |
| App target, composition root (`App/Composition/`) | everything | — |
| App target, previews (`App/Previews/`, `DEBUG`) | as views, plus `BurnieProviders` for descriptors | `Infra` |

Notes:

- `BurnieProviders` and `BurnieApplication` never see each other: the composition root hands provider bundles to the
  app model as `BurnieInterface` values.
- `BurnieInfra` never knows a provider. A provider-specific detail (paths, binary names, hosts) is data the
  provider passes to a generic adapter.
- Views import `BurnieApplication` only to get `AppModel`. Every other Application symbol is `internal` (`A-1`).

### 3.3 Rules for every module (`G-*`)

- **G-1** If something doesn't fit the layers, ports or glossary, stop and escalate in a single batched question.
  Never work around the spec.
- **G-2** A new concept enters the glossary (this file) in the same PR that introduces its type.
- **G-3** `Package.swift` and `project.yml` dependencies match section 3.2 exactly.
- **G-4** One top-level type per file, named like the file. Extensions are `Type+Topic.swift`.
- **G-5** No `switch` on a provider and no comparison with a specific `ProviderID` outside `BurnieProviders`.
  (Enforced by the compiler once `ProviderID` is a newtype; checked by script before.)
- **G-6** No `Date()`, `Date.now`, `TimeZone.current`, `Locale.current`, `Calendar.current` outside `BurnieInfra`
  and the composition root. Time comes from `Clock`; locale and time zone come in as parameters. The one exception is
  the start of a SwiftUI `TimelineView` schedule (`.periodic(from: .now, …)`), which only paces redraws; the values
  drawn still take `now` from the app model's clock.
- **G-7** No `print`, `NSLog` or `debugPrint` anywhere. Diagnostics go through the `DiagnosticsLog` port.
- **G-8** No `TODO`, `FIXME`, `XXX`, commented-out code or unused declarations.
- **G-9** No force unwrap or `try!` outside tests, except on values that are compile-time constants
  (a literal URL, a fixed time zone identifier) with a comment saying so.
- **G-10** Public API is the minimum the next layer needs. Default to `internal`.
- **G-11** Swift 6 strict concurrency stays `complete`. No `@unchecked Sendable` outside `BurnieInfra`, and there
  only with a comment naming what serializes the state.
- **G-12** Nothing sensitive in code, fixtures, docs, commits or PR text (root `AGENTS.md`).

---

## 4. Domain (`BurnieDomain`)

The internal language as types. Pure: values, total functions, no I/O, no async, no time source.

### 4.1 Rules (`D-*`)

- **D-1** Only `import Foundation`. From Foundation, only value types and pure functions: `Date`, `DateInterval`,
  `Calendar` built with an explicit time zone, `Locale` passed in, `Data`, `URL` as a value, `Codable`.
- **D-2** No `class`, no `actor`, no `async`, no `Task`, no global mutable state, no `static var`.
- **D-3** No `Date()`, `TimeZone.current`, `Locale.current`, `FileManager`, `URLSession`, `Process`, `UserDefaults`,
  `Bundle`, `ProcessInfo`, `NotificationCenter`.
- **D-4** Every public type is `Sendable` and `Equatable`. Types that are persisted are also `Codable` with an explicit,
  tested wire format (section 12).
- **D-5** Functions are total: no `fatalError`, no `precondition` on inputs. An invalid input is unrepresentable
  (type) or mapped to a defined value (clamp, nil) that is documented.
- **D-6** No user-visible strings. Copy lives in `BurnieInterface`.
- **D-7** Every algebraic operation has its laws listed in section 4.4 and a property test.
- **D-8** Nothing provider-specific: no Claude or Cursor names, meter IDs, URLs or plan names.

### 4.2 Types

Sketches. Names are binding; exact signatures are settled in the PR that writes them, without changing meaning.

```swift
// Identity
struct ProviderID: RawRepresentable, Hashable, Codable, Sendable { let rawValue: String }
struct MeterID: RawRepresentable, Hashable, Codable, Sendable { let rawValue: String }
struct PlanName: RawRepresentable, Hashable, Codable, Sendable { let rawValue: String }

// Quantities
struct Fraction: Hashable, Codable, Sendable, Comparable { let value: Double }   // init clamps to 0…1, NaN → 0
struct Tokens: Hashable, Codable, Sendable, Comparable, AdditiveArithmetic { let count: Int }
struct Cents: Hashable, Codable, Sendable, Comparable, AdditiveArithmetic { let amount: Int }

// Meters
struct Meter { let id: MeterID; let fill: Fraction; let value: MeterValue; let caption: MeterCaption; let period: DateInterval? }
enum MeterValue { case percent(Int); case money(used: Cents, limit: Cents?) }
enum MeterCaption { case resetsIn(Date), resetsAt(Date), cycleEnds(Date), noActiveSession, onDemandIdle }
struct MeterSet { let primary: Meter; let others: [Meter] }      // non-empty; `all` = [primary] + others

// Snapshot
enum UsageUnit { case tokens, money }
enum TodayUsage { case tokens(Tokens), money(Cents) }
struct SnapshotFeatures { var onDemand: Meter? }
struct Stamped<Value> { var value: Value; var at: Date }
struct LimitsView { var plan: PlanName?; var meters: MeterSet }
enum SnapshotContent {
    case limits(Stamped<LimitsView>, today: TodayUsage?)   // today nil if activity failed or never loaded
    case activityOnly(Stamped<TodayUsage>)                 // limits failed or never loaded
}
struct UsageSnapshot {
    var provider: ProviderID
    var content: SnapshotContent
    var features: SnapshotFeatures
    var issue: ProviderIssue?    // partial issue
    // Computed, for views and formatters: fetchedAt (the content's stamp), plan, meters, today.
}
enum ProviderState { case loading, ready(UsageSnapshot), failed(ProviderIssue) }

// Parts
struct LimitsPart { var plan: PlanName?; var meters: MeterSet; var unit: UsageUnit; var features: SnapshotFeatures }
struct ActivityPart { var tokens: [LocalDay: Tokens]; var spent: [LocalDay: Cents] }
enum Part { case limits(LimitsPart), activity(ActivityPart) }
enum PartKind { case limits, activity }
enum Latest<Value> {
    case success(Stamped<Value>)
    case failure(ProviderIssue, at: Date, lastSuccess: Stamped<Value>?)
    // recording(_ outcome:, at:) is the only way forward: a success replaces everything,
    // a failure keeps the previous lastSuccess. Computed: lastSuccess, issue.
}

// Issues
enum ProviderIssue: Error { case notFound, signInExpired, rateLimited(retryAt: Date?), offline,
                            unexpectedResponse(String), specific(SpecificIssue) }
struct SpecificIssue: Hashable, Codable, Sendable { let code: String }   // copy comes from the descriptor

// Time and history
struct LocalDay              // as today; Strideable, Codable as "yyyy-MM-dd", usable as a JSON key
enum ActivityWindow          // dayCount = 8; days(endingAt:)
struct DailyPoint { var day: LocalDay; var tokens: Tokens }
struct UsageHistory          // record(_:for:today:), points(for:endingAt:count:); retentionDays = 35
struct WeekChart { let days: [LocalDay]; let providers: [ProviderID]; let series: [ProviderID: [Tokens]]; let peak: Tokens }

// Refresh
struct RefreshPolicy { let interval: TimeInterval; let jitter: TimeInterval; let staleOnOpen: TimeInterval?; let needsNetwork: Bool }
enum RefreshTrigger { case timer, popoverOpened, manual, wake, networkRestored, activityChanged }
struct RateLimitBackoff      // as today

// App features
enum Favorite                // effective(stored:enabled:), toggling(_:stored:enabled:), ring(…)
enum RingState { case hidden, visible(ProviderID, Fraction) }   // fraction rounded to whole percents
enum FeatureToggle: String, CaseIterable { case onDemand }      // raw value = settings key suffix
struct AppSettings { var enabled: Set<ProviderID>; var favorite: ProviderID?; var showRing: Bool;
                     var showWeekChart: Bool; var hiddenFeatures: Set<FeatureToggle> }
```

### 4.3 Pure operations

| Operation | Meaning | Replaces |
| --- | --- | --- |
| `UsageSnapshot.compose(provider:limits:activity:today:)` | From the latest limits and activity to `ProviderState`. Rules B-10…B-16. | `CompositeUsageProvider.composedSnapshot` |
| `Latest.recording(_ outcome:, at:)` | A success becomes `.success(stamped)`; a failure becomes `.failure` carrying the previous `lastSuccess`. Rule B-8. | the `unit` variable in `CompositeUsageProvider` |
| `UsageSnapshot.merge(_ previous:, _ next:)` | When `next` is `.activityOnly` and `previous` is `.limits`, the result is `previous`'s stamped limits view with `next`'s today's usage; otherwise `next`. Rule B-17. | `keepingMeters(of:)` |
| `ProviderState.failing(_ issue:, previous:)` | A total failure over a cached snapshot becomes `.ready(previous with issue)`; without one, `.failed(issue)`. Rule B-18. | `with(issue:)` + store code |
| `UsageSnapshot.hiding(_ toggles:)` | Removes hidden features. Rule B-40. | `hidingOnDemand()` |
| `UsageHistory.record(_:for:today:)` | Overwrites the given days, prunes past retention. | same |
| `WeekChart.make(history:providers:today:)` | 7 days ending today, zero-filled, shared peak. | logic in `WeekChart` view |
| `Favorite.*`, `RingState` | As today, with the ring reading `meters.primary`. | `meters.first` |
| `RefreshPolicy.shouldRun(for:lastRun:now:)` | As today. | same |
| `RateLimitBackoff.*` | As today. | same |

### 4.4 Laws

Each law is a property test in `BurnieDomainTests` (section 16.4). `≡` means equal by `Equatable`.

- **Fraction**: `Fraction(x).value ∈ [0, 1]` for every `Double` including ±∞ and NaN; `Fraction(Fraction(x).value) ≡ Fraction(x)` (idempotent clamp).
- **Tokens / Cents**: `AdditiveArithmetic` laws: associativity, commutativity, `.zero` identity.
- **Latest**: `recording(.success(v), at: t).lastSuccess ≡ Stamped(v, t)`; `recording(.failure(e), at: t).lastSuccess ≡ lastSuccess`
  (a failure never loses the last success); `recording(.failure(e), at: t).issue ≡ e`.
- **Merge** (a semigroup: "last snapshot with limits wins the limits"):
  - associativity: `merge(merge(a, b), c) ≡ merge(a, merge(b, c))`
  - idempotence: `merge(a, a) ≡ a`
  - right-biased: if `b.content` is `.limits` then `merge(a, b) ≡ b`
  - `today`, `features` and `issue` always come from the right.
- **Compose**: total over every combination of `Latest<LimitsPart>?` × `Latest<ActivityPart>?` (nil, success, failure).
  (That the result never shows neither meters nor today's usage is now guaranteed by `SnapshotContent`, not by a law.)
- **Favorite**: `toggling(id, toggling(id, s, e), e) ≡ s` when `id ∈ e`; `effective` result is always in `enabled` or nil;
  toggling a disabled provider is the identity.
- **LocalDay**: `d.advanced(by: n).advanced(by: -n) ≡ d`; `d.distance(to: d.advanced(by: n)) == n`;
  `LocalDay(iso: d.iso) ≡ d`; ordering agrees with `distance`.
- **UsageHistory**: `record(p)` twice ≡ once (idempotent); after `record`, no day older than retention remains;
  `points(count: n)` always has `n` consecutive days ending today.
- **RingState**: `visible` fraction is a multiple of 0.01.
- **RateLimitBackoff**: waits are non-decreasing across consecutive 429s and capped at 60 minutes; `reset` returns to the initial value.
- **Codable**: `decode(encode(x)) ≡ x` for every persisted type.

---

## 5. Interface (`BurnieInterface`)

The contract between the UI, the runtime and the providers. Types, protocols and pure presentation; no state.

### 5.1 Rules (`I-*`)

- **I-1** Imports only `Foundation` and `BurnieDomain`.
- **I-2** No stored mutable state, no `class`, no `actor`.
- **I-3** A type here that is identical to a domain type is deleted (the domain type is used instead).
- **I-4** Every capability is an optional field of `ProviderCapabilities`; every snapshot feature is an optional field
  of `SnapshotFeatures` (domain). Adding one is a spec change.
- **I-5** Ports are the minimum an adapter must do. A port never exposes a macOS type.
- **I-6** Use cases are what the UI calls; ports are what providers and infra implement. A provider never implements
  a use case; a view never calls a port.
- **I-7** All copy lives in `Presentation/`. Copy is English, sentence case, and tested for the exact text.

### 5.2 Ports

| Port | Purpose | Implemented by | Used by |
| --- | --- | --- | --- |
| `Clock` | `now`, `timeZone`. | `SystemClock` | everyone |
| `Sleeper` | `sleep(for:)` that tests can drive. | `TaskSleeper` | Application interpreter (timers) |
| `HTTPClient` | Send an `HTTPRequest`, get data and status. Only allowed hosts. | `URLSessionHTTPClient` | Providers |
| `FileReading` | List, attributes, read from offset, exists, is executable. Read-only. | `LocalFileReader` | Providers |
| `SecretReader` | Read a generic password from the Keychain. Never writes. | `SecurityCLIKeychain` | Providers |
| `KeyValueDatabase` | Read one row of a SQLite key-value table. Read-only. | `SQLiteKeyValueReader` | Providers |
| `ProviderStorage` | Load and save one provider's private JSON (Claude's log index), namespaced. | `JSONFileStore` | Providers |
| `ProcessRunner` | Run an allowlisted executable with fixed arguments, clean environment, no output, a timeout; return the exit status. | `FoundationProcessRunner` | Providers |
| `ActivityWatcher` | `start(onChange:)` / `stop()` over directories. | `DirectoryWatcher` (FSEvents) | Providers (declared), Application (driven) |
| `DiagnosticsLog` | Counts, timings and status codes for a category. Never secrets. | `OSDiagnosticsLog` | Providers, Application |
| `SnapshotCache` | Load and save the app's own files: snapshots and history. | `JSONFileStore` | Application |
| `SettingsStore` | Load and save `AppSettings` with the keys of section 12. | `UserDefaultsSettingsStore` | Application |
| `SystemEvents` | Wake and network reachability callbacks. | `MacSystemEvents` | Application |
| `LoginItem` | Read and set launch at login. | `SMAppLoginItem` | Application |
| `Updater` | Report an available version; open the installer. | `SparkleUpdater` | Application |
| `URLOpener` | Open an external URL. | `WorkspaceURLOpener` | Application |
| `AppLifecycle` | Quit. | `NSAppLifecycle` | Application |

### 5.3 Provider contract

```swift
struct ProviderDescriptor: Sendable {
    let id: ProviderID
    let displayName: String              // "Claude Code"
    let shortName: String                // "Claude", chart legend
    let color: ColorPair                 // light and dark RGB; Components turns it into a Color
    let dashboard: Link                  // title + URL for the footer
    let meters: [MeterDescriptor]        // id + label, in display order; `placeholderMeters` while loading
    let placeholderMeters: [MeterID]
    let copy: ProviderCopy               // issue rows, renewal failed, status lines
}

struct ProviderCopy: Sendable {
    let notFound: String
    let signInExpired: String
    let renewalFailed: String
    let specific: [SpecificIssue: String]
    let status: @Sendable (StatusContext) -> String   // healthy status line on the providers screen
}

struct StatusContext: Sendable { let plan: PlanName?; let sourceLocation: String? }
struct MeterDescriptor: Sendable { let id: MeterID; let label: String }
struct Link: Sendable { let title: String; let url: URL }
struct ColorPair: Sendable { let light: RGB; let dark: RGB }   // RGB: three Doubles in 0…1

struct ProviderCapabilities: Sendable {
    var signInRenewal: SignInRenewal?    // nil: Burnie can't renew this provider's sign-in
    var sourceLocation: String?          // "~/.claude", shown in the status line
}

struct SignInRenewal: Sendable {
    let run: @Sendable () async -> Bool  // true once the provider's own app renewed the sign-in
}
// Claude builds it over ProcessRunner with the executable it found and fixed arguments (B-61, B-63).

struct RefreshTask: Sendable {
    let name: String                     // unique within the provider, for logs and job keys
    let part: PartKind
    let policy: RefreshPolicy
    let watcher: (any ActivityWatcher)?  // only activity tasks; triggers `.activityChanged`
    let run: @Sendable () async -> Result<Part, ProviderIssue>
}

struct ProviderBundle: Sendable {
    let descriptor: ProviderDescriptor
    let capabilities: ProviderCapabilities
    let tasks: [RefreshTask]
}
```

Rules for the contract:

- A provider has at least one limits task or one activity task; at most one task per part kind (a provider that needs
  two reads for one part combines them inside its task, as Cursor's activity does today).
- `run` never throws and never crashes: every failure is an `Outcome` failure with a `ProviderIssue`.
- A task's result is the full part, not a delta.

### 5.4 Use cases

Each use case is one feature of the app, documented where it's declared. They're grouped in `UseCases`,
a struct of closures, so previews and tests replace them with no-ops or recorders.

| Use case | Signature | Feature |
| --- | --- | --- |
| `OpenPopover` | `() -> Void` | Opening the popover refreshes what's stale and resets to the usage screen. Debounced 1 s. |
| `RefreshUsage` | `(force: Bool) async -> Void` | The Refresh button (`force: true`): every enabled task regardless of age, except during backoff. |
| `RenewSignIn` | `(ProviderID) async -> Bool` | The expired sign-in button: the provider's app renews it, then its limits refresh. |
| `SetProviderEnabled` | `(ProviderID, Bool) -> Void` | Track or stop tracking a provider. Keeps cache and history. |
| `ToggleFavorite` | `(ProviderID) -> Void` | The heart. One favorite at a time. |
| `SetRingShown` | `(Bool) -> Void` | The "Ring in menu bar" switch. |
| `SetWeekChartShown` | `(Bool) -> Void` | The "Last 7 days" switch. |
| `SetFeatureShown` | `(FeatureToggle, Bool) -> Void` | Feature switches ("On-demand"). |
| `SetLaunchAtLogin` | `(Bool) -> Void` | Launch at login. |
| `ReadLaunchAtLogin` | `() -> Void` | Re-reads it when the providers screen appears (System Settings can change it). |
| `InstallUpdate` | `() -> Void` | Opens the updater's window. |
| `OpenDashboard` | `(ProviderID) -> Void` | Footer link to the provider's usage page. |
| `Quit` | `() -> Void` | Footer Quit, ⌘Q. |

### 5.5 App state

The pure value the views render. Built by Application (section 7.4); equatable so SwiftUI only redraws on change.

```swift
struct AppState: Equatable, Sendable {
    var providers: [ProviderPanel]       // every known provider, registry order
    var ring: RingState
    var weekChart: WeekChart?            // nil when the switch is off or nothing is enabled
    var lastUpdated: Date?               // most recent fetchedAt among enabled providers
    var isRefreshing: Bool
    var settings: AppSettings
    var visibleToggles: [FeatureToggle]  // toggles some enabled snapshot has a feature for
    var launchAtLogin: Bool
    var availableUpdate: String?
}

struct ProviderPanel: Equatable, Sendable {
    let descriptor: ProviderDescriptor   // Equatable by id
    var isEnabled: Bool
    var isFavorite: Bool                 // effective favorite
    var state: ProviderState             // already filtered by feature toggles
    var canRenewSignIn: Bool
    var sourceLocation: String?
}
```

### 5.6 Presentation

Everything that turns domain values into text, moved from `BurnieCore/Format/`:
`TokenCountFormatter`, `MoneyFormatter`, `MeterValueFormatter`, `MeterCaptionFormatter`, `TodayUsageFormatter`,
`LastUpdatedFormatter`, `DayLabelFormatter`, `RingAccessibilityLabel`, `StatusLine`, `IssueMessage`, and `Copy`
(every fixed string the views show: "Usage", "Providers", "Last 7 days", "Refresh sign-in", "Quit"…).
Provider-specific text comes from `ProviderDescriptor.copy`, never from a switch.

---

## 6. Providers (`BurnieProviders`)

Each provider turns its sources into parts. Sources are internal (agreed): nobody outside a provider's folder knows
what it reads, how often, or in how many calls.

### 6.1 Rules (`P-*`)

- **P-1** Imports `Foundation`, `BurnieDomain`, `BurnieInterface` only. All I/O through ports.
- **P-2** Folder per provider: `Claude/`, `Cursor/`. Shared helpers in `Shared/` (HTTP fetch rules, ISO 8601, CSV,
  `Retry-After`). Nothing in `Shared/` mentions a provider.
- **P-3** Each provider exposes exactly one public entry point: `enum ClaudeProvider { static func bundle(_ ports: ClaudePorts) -> ProviderBundle }`.
  `ClaudePorts` / `CursorPorts` are structs of the ports and values it needs (home, user name, user agent).
- **P-4** DTOs never leave their provider's folder. Mappers are pure functions from DTO to domain parts.
- **P-5** A provider may keep a **memo**: private state that only avoids repeated work (the log index, the hourly
  profile plan). A memo never decides what the UI shows beyond what a fresh read would; losing it only costs time.
  Memos live in an `actor` inside the provider and persist only through `ProviderStorage`.
- **P-6** Each provider declares its hosts; the `HTTPClient` it gets only reaches those (B-60).
- **P-7** A provider never refreshes, writes or rotates another app's credentials (B-61, B-62).
- **P-8** Provider-specific issues use `.specific(SpecificIssue(code:))` with a code declared in the provider and copy
  in its descriptor.
- **P-9** Every DTO has a fixture with the real shape and invented values (`T-6`).
- **P-10** Shared code is extracted on the second use, not the first; duplicated logic between providers is a defect.

### 6.2 Claude

- **Descriptor:** id `claude`; names "Claude Code" / "Claude"; dashboard "Open Claude usage page" →
  `https://claude.ai/settings/usage`; meters `session` ("Session · 5h", primary) and `weekly` ("Weekly");
  placeholders `[session, weekly]`; status "Reading local logs · {sourceLocation}".
- **Tasks:** `limits` (OAuth usage + hourly profile memo; policy 5 min ± 30 s, stale on open 60 s, needs network) and
  `activity` (incremental log scan with the index memo; 5 min, no jitter, not refreshed on open, no network,
  watched by FSEvents over the existing log roots).
- **Capabilities:** `signInRenewal` when an installed `claude` executable is found (native installer, Homebrew on
  Apple silicon, Homebrew on Intel/npm, in that order); `sourceLocation` from the existing log root or the default.
- **Specific issues:** `missingScope` (token without `user:profile`, from `claude setup-token`).
- **Hosts:** `api.anthropic.com`.

### 6.3 Cursor

- **Descriptor:** id `cursor`; names "Cursor" / "Cursor"; dashboard "Open Cursor dashboard" →
  `https://cursor.com/dashboard/spending`; meters `cursorModels` ("Cursor Models", primary on individual plans),
  `otherModels` ("Other Models"), `included` ("Included usage", primary on team and enterprise plans), `onDemand`
  ("On-demand", only as a feature); placeholders `[cursorModels, otherModels]`;
  status "Signed in · {Plan} plan" or "Signed in".
- **Tasks:** `limits` (usage summary; 10 min ± 30 s, stale on open 60 s, needs network) and `activity`
  (events CSV for tokens plus paged usage events for today's spend, combined; 30 min, no jitter, stale on open 10 min,
  needs network).
- **Capabilities:** none today.
- **Specific issues:** none today.
- **Hosts:** `cursor.com`.

---

## 7. Application (`BurnieApplication`)

The runtime: the only owner of state, the scheduler, and the implementation of the use cases.

### 7.1 Rules (`A-*`)

- **A-1** The only public types are `AppModel` and its factory input `AppEnvironment` (ports + provider bundles).
- **A-2** State changes only in the reducer: `reduce(_ state: RuntimeState, _ event: Event) -> (RuntimeState, [Effect])`,
  pure and synchronous.
- **A-3** Effects are performed by one interpreter that calls ports and feeds results back as events.
  Nothing else calls a port.
- **A-4** There is no scheduler actor. Job state (`RuntimeState.jobs`) lives in the reducer; `Scheduling.canRun` and
  `Scheduling.delay` are pure functions over a `JobState`; the interpreter only holds the live timer `Task`s and
  turns `scheduleTimer`/`cancelTimer` effects into `Sleeper` waits that come back as `timerFired` events.
- **A-5** Time only from `Clock`; waiting only through `Sleeper`. Tests never wait for real time.
- **A-6** `AppState` is derived by a pure function `AppState.derive(from: RuntimeState)` and holds no time-dependent
  value. Views may evaluate pure presentation functions of `(state, now)` from `BurnieInterface` (`isStale`,
  `elapsedFraction`, formatters) with `now` from `AppModel.clock` under a `TimelineView`; they hold no state and
  make no decisions.
- **A-7** Every behavior in section 11 tagged *Application* has a test that names its ID.

### 7.2 Runtime state

```swift
struct RuntimeState: Equatable {
    var settings: AppSettings
    var parts: [ProviderID: ProviderParts]       // Latest<LimitsPart>?, Latest<ActivityPart>?
    var shown: [ProviderID: ProviderState]       // after compose + merge; what is cached on disk
    var history: UsageHistory
    var runningRefreshes: Int
    var lastPopoverOpen: Date?
    var launchAtLogin: Bool
    var availableUpdate: String?
    var jobs: [JobKey: JobState]                 // one per refresh task of each enabled provider
    var isOnline: Bool
}

struct JobKey: Hashable { let provider: ProviderID; let task: String }   // task = RefreshTask.name
struct JobState: Equatable {
    var policy: RefreshPolicy
    var isRunning: Bool                           // single flight (B-32)
    var lastRun: Date?
    var backoff: RateLimitBackoff
}

enum Scheduling {
    /// B-31, B-33, B-34: not running, not in backoff, online or no network needed, and the policy accepts the trigger.
    static func canRun(_ job: JobState, trigger: RefreshTrigger, isOnline: Bool, now: Date) -> Bool
    /// B-35: until `retryAt` during backoff, else interval ± jitter. `jitter` is a sample in -1…1 the
    /// interpreter draws and puts in the event, so the function stays pure and tests pass a fixed value.
    static func delay(for job: JobState, now: Date, jitter: Double) -> TimeInterval
}
```

### 7.3 Events and effects

| Event | Reducer outcome | Effects |
| --- | --- | --- |
| `launched(cached snapshots, history, settings, now)` | Ready states from cache, else loading; a `JobState` per task of each enabled provider. | `startSystemEvents`; `startWatcher` per enabled provider; `runTask` for every job (B-37) |
| `popoverOpened(now)` | Ignored if < 1 s since the last one. | `runTask` for jobs where `canRun(.popoverOpened)` |
| `refreshRequested(force, now)` | `runningRefreshes += 1` | `runTask` for jobs where `canRun(.manual)` or `canRun(.popoverOpened)` |
| `trigger(RefreshTrigger, jobs, now)` | — | `runTask` for the given jobs where `canRun` (the generic form the rows above and below use) |
| `taskStarted(key)` | `isRunning = true` (ignored if already running, B-32). | `cancelTimer(key)` (B-36: the timer was already released) |
| `taskFinished(key, outcome, at, jitter)` | `isRunning = false`; `lastRun = at`; backoff recorded on 429, reset otherwise (B-33); update `Latest`; compose; merge; record history on activity success. | `saveSnapshot`; `saveHistory`; `scheduleTimer(key, after: delay(…))` (B-35) |
| `timerFired(key, now)` | — | `runTask(key)` if `canRun(.timer)` |
| `providerToggled(id, isOn, now)` | Update settings; add or remove `id`'s jobs (B-51). | `saveSettings`; `startWatcher`/`stopWatcher`; on add `runTask` for the new jobs, on remove `cancelTimer` for the old ones (B-37) |
| `favoriteTapped(id)` | `Favorite.toggling`. | `saveSettings` |
| `settingChanged(…)` | Ring, week chart, feature toggles. | `saveSettings` |
| `renewRequested(id)` / `renewFinished(id, ok, now)` | `runningRefreshes` ± 1 | `renewSignIn(id)`; on success `runTask` for `id`'s limits job if `canRun(.manual)` (B-23) |
| `woke` | — | `wait(3 s, then: .trigger(.wake, all jobs))` (B-38) |
| `networkChanged(isOnline, now)` | `isOnline = isOnline`. | on offline → online, `runTask` for jobs where `canRun(.networkRestored)` (B-38) |
| `activityChanged(id, now)` | — | `runTask` for `id`'s activity job if `canRun(.activityChanged)` |
| `launchAtLoginRead(Bool)` / `updateFound(String?)` | Store it. | — |

The interpreter performs `runTask(key)` by sending `taskStarted(key)`, awaiting the task's `run`, and sending
`taskFinished(key, outcome, at: clock.now, jitter: random in -1…1)`. A task whose job was removed while it ran is
dropped on `taskFinished` (the key no longer exists). Chained activation (B-37) is free: events are processed in
order on the main actor.

### 7.4 App model

`@MainActor @Observable final class AppModel { private(set) var state: AppState; let useCases: UseCases; let clock: Clock }`.
`clock` is for the views' `TimelineView` and for deterministic previews (A-6); previews get a fixed clock.
It holds `RuntimeState` privately, runs the reducer on each event, publishes `AppState.derive(…)`, and hands
effects to the interpreter. Previews build it with `AppModel.preview(_ state: AppState)`, which has no-op use cases
and no runtime.

### 7.5 Scheduling

Today's `RefreshScheduler` actor is replaced by `RuntimeState.jobs`, the `Scheduling` functions and the
`runTask`/`scheduleTimer`/`cancelTimer` effects above, keeping today's semantics exactly (B-30…B-39): one job per
refresh task of each enabled provider, a timer per job with jitter, single flight, backoff on 429, triggers filtered
by `RefreshPolicy.shouldRun`, offline skips tasks that need the network, the timer releases itself before running.
Every one of those is a reducer test: state + event → state + effects, with `FixedClock` and a fixed jitter sample.

---

## 8. Infra (`BurnieInfra`)

Dumb adapters. Each implements one port and nothing else.

### 8.1 Rules (`X-*`)

- **X-1** One adapter per port per file; the adapter's name says the technology (`URLSessionHTTPClient`).
- **X-2** No business rules: no `ProviderID`, no `Meter`, no decisions about what to show. If an adapter needs a
  provider detail, it's a parameter.
- **X-3** Never logs or stores secrets. Logs use `os.Logger` with the app's subsystem and a category; numbers are
  public, every other interpolation is `.private`. Never tokens, cookies, user ids or response bodies.
- **X-4** Read-only over other apps' files and the Keychain. Writes only to `~/Library/Application Support/Burnie/`
  (0700 folder, 0600 files, atomic), to `UserDefaults`, and what Sparkle needs for an update the user asked for.
- **X-5** `ProcessRunner` only runs `/usr/bin/security` and an installed `claude`, by absolute path, with fixed
  arguments, a minimal environment (`HOME`, `USER`, `LOGNAME`, a system `PATH`), a working directory without
  `.claude/`, null stdin/stdout/stderr and a timeout.
- **X-6** SQLite opens read-only with a timeout; if busy, copies the database and its WAL to a private 0700 temporary
  directory, reads the copy and deletes it in a `defer`.
- **X-7** `HTTPClient` uses an ephemeral session, no cookies or cache, follows no redirects, and checks the host
  against the allowlist before any header is sent.
- **X-8** `@unchecked Sendable` only with a comment naming the queue or lock that serializes state.

### 8.2 Adapters

| Adapter | Port | From |
| --- | --- | --- |
| `SystemClock` | `Clock` | `BurnieSystem/SystemClock.swift` |
| `TaskSleeper` | `Sleeper` | new (today `Task.sleep` inline in the scheduler) |
| `URLSessionHTTPClient` | `HTTPClient` | `BurnieSystem` |
| `LocalFileReader` | `FileReading` | `BurnieSystem` (+ `exists`, `isExecutable`) |
| `SecurityCLIKeychain` | `SecretReader` | `BurnieSystem` |
| `SQLiteKeyValueReader` | `KeyValueDatabase` | `BurnieSystem` |
| `JSONFileStore` | `SnapshotCache`, `ProviderStorage` | `BurnieSystem` |
| `FoundationProcessRunner` | `ProcessRunner` | generic half of `ClaudeCodeSignInRenewer` |
| `DirectoryWatcher` | `ActivityWatcher` | `ClaudeLogDirectoryWatcher`, made generic |
| `OSDiagnosticsLog` | `DiagnosticsLog` | the `Logger` calls in provider assembly |
| `UserDefaultsSettingsStore` | `SettingsStore` | `App/Store/Setting+UserDefaults.swift` |
| `MacSystemEvents` | `SystemEvents` | `App/Store/SystemEventMonitor.swift` |
| `SMAppLoginItem` | `LoginItem` | `App/Store/LaunchAtLogin.swift` |
| `SparkleUpdater` | `Updater` | `App/Store/AppUpdater.swift` |
| `WorkspaceURLOpener` | `URLOpener` | `openURL` in `FooterMenu` |
| `NSAppLifecycle` | `AppLifecycle` | `NSApp.terminate` in `FooterMenu` |

---

## 9. Components (`BurnieComponents`)

Decided here (the question was left open): Components is its own SwiftPM module, so the compiler guarantees that a
component can't reach the app model, a provider or an adapter.

### 9.1 Rules (`C-*`)

- **C-1** Imports `SwiftUI`, `BurnieDomain`, `BurnieInterface`.
- **C-2** Inputs are values and closures. No `@Environment` of app types, no `AppModel`, no use cases by name.
- **C-3** Local UI state only (`@State` for hover, spinning, an in-flight button).
- **C-4** Colors, fonts and measurements come from `DesignTokens`; provider colors come from
  `ProviderDescriptor.color`. No literal colors or magic numbers.
- **C-5** No literal user-visible text: strings come in as parameters or from `Copy`.
- **C-6** Every component has a `#Preview` and a render smoke test (`T-9`).
- **C-7** Accessibility labels for every icon-only control.

### 9.2 Components

`BurnieDivider`, `BurnieSwitchStyle`, `ChipButton`, `HoverHighlightStyle`, `IconButton`, `IssueRow`, `MeterView`,
`PlanChip`, `Spin`, `SwitchRow`, `UpdateBadge`, `FooterItem`, `MenuBarIcon`, `WeekChartView`, `ProviderRow`,
`SignInRenewalRow`, `PreviewFrame`, and `DesignTokens` (today's `Tokens.swift`, minus provider colors).

---

## 10. App target

### 10.1 Rules (`V-*`)

- **V-1** Views read `AppModel.state` and `AppModel.clock` and call `AppModel.useCases`. Nothing else from Application.
- **V-2** Views contain no business logic: they select, lay out and wire. Branching on a capability or feature with
  `if let` is fine; branching on a provider is not (`G-5`).
- **V-3** The composition root (`App/Composition/`) is the only code that imports `BurnieProviders` and
  `BurnieInfra`. It builds adapters, provider bundles and the app model, in that order. Previews (`App/Previews/`,
  `#if DEBUG`) may import `BurnieProviders` only to use the real descriptors.
- **V-4** Previews build an `AppState` value and `AppModel.preview(_:)`. Every scenario of section 16.7 has a preview.
- **V-5** AppKit only for what SwiftUI can't do (window placement, the template menu bar image).

### 10.2 Views

`BurnieApp`, `RootView`, `UsageView`, `UsageHeader`, `ProviderSection`, `ProvidersView`, `FooterMenu`,
`EmptyProvidersView`, `LaunchAtLoginRow`, `RingInMenuBarRow`, `UpdateRow`, `MenuBarLabel`, `PopoverPlacement`,
`WindowReader`, and the previews.

---

## 11. Behavior catalog

What Burnie does today and must keep doing. The refactor changes structure, not behavior.
Each item has an ID; the test that pins it includes the ID in its name (`@Test("B-12 …")`).
"Layer" says where the test lives after the migration.

### 11.1 Meters and snapshots

| ID | Behavior | Layer |
| --- | --- | --- |
| B-1 | A meter's fill is clamped to 0…1; NaN reads as 0. | Domain |
| B-2 | A percent meter from an API's 0–100 value clamps to 0…100 and rounds the shown percent. | Domain |
| B-3 | The pace is `(now − start) / duration`; nil without a period, with zero duration, or when `now` is outside it. | Domain |
| B-4 | On-demand has no period: it shows no pace tick. | Providers |
| B-5 | The part of the fill past the pace draws in the over-pace color; all of it is on pace without a tick. | Components |
| B-6 | A snapshot older than 30 minutes dims its values and today's usage. | Domain + Components |
| B-7 | Today's usage reads money when the latest successful limits measure money and the activity added up today's spend; tokens otherwise. | Domain |
| B-8 | A failed limits refresh doesn't flip today's usage from money back to tokens (the unit is the last successful one). | Domain |
| B-9 | Plan chips: Claude `pro`/`max`/`team`/`enterprise` (with or without `claude_`) → `PRO`/`MAX`/`TEAM`/`ENTERPRISE`, else none; Cursor `free`, `pro`, `pro_plus`→`PRO+`, `ultra`, `business`/`team`→`TEAMS`, `enterprise`, else uppercased. | Providers |

### 11.2 Composing and merging

| ID | Behavior | Layer |
| --- | --- | --- |
| B-10 | Limits and activity combine into one snapshot with meters and today's usage. | Domain |
| B-11 | Refreshing one part keeps the latest result of the other. | Application |
| B-12 | Failed limits with activity: a snapshot without meters, with today's usage and the limits issue. | Domain |
| B-13 | Failed activity with limits: meters without today's usage and without an issue. | Domain |
| B-14 | Nothing to show: total failure with the limits issue, else the activity issue, else `notFound`. | Domain |
| B-15 | Activity before any limits: `.activityOnly`, `fetchedAt` = activity's time. | Domain |
| B-16 | `fetchedAt` is the limits' time when the content is `.limits`. | Domain |
| B-17 | An `.activityOnly` snapshot over a cached `.limits` one keeps the cached limits view and its stamp (stale data beats a gap). | Domain |
| B-18 | A total failure over a cached snapshot shows the cache with the issue on top; without a cache, the failure alone. | Domain |
| B-19 | The cache is saved after every successful snapshot, as shown (after merge). | Application |

### 11.3 Issues and sign-in

| ID | Behavior | Layer |
| --- | --- | --- |
| B-20 | `rateLimited` and `offline` show no issue row: the header's age already says the data is old. | Interface |
| B-21 | Issue copy per provider: not found, sign-in expired, missing scope (Claude), unexpected ("Couldn't read usage. Burnie may need an update."). | Interface + Providers |
| B-22 | An expired sign-in shows "Refresh sign-in" only when the provider can renew; on failure the row shows the renewal-failed copy. | Components + Application |
| B-23 | A successful renewal triggers a manual refresh of that provider's limits. | Application |
| B-24 | HTTP: no network or timeout → offline; 429 → rate limited with `Retry-After` (seconds or HTTP date); 5xx → offline; other non-2xx → unexpected. | Providers |
| B-25 | Claude: 401 → sign-in expired; 403 mentioning `user:profile` → missing scope; other 403 → sign-in expired; an expired token is detected before any request. | Providers |
| B-26 | Cursor: 3xx, 401, 403 or HTML instead of data → sign-in expired; no database or row → not found; malformed or expired JWT → sign-in expired without network. | Providers |
| B-27 | Claude credentials: Keychain first, then the credentials file. | Providers |
| B-28 | Claude's plan comes from the profile at most once an hour, keeps the last good one, and falls back to the credentials' plan. | Providers |

### 11.4 Refresh

| ID | Behavior | Layer |
| --- | --- | --- |
| B-30 | Policies: Claude limits 5 min ± 30 s, stale on open 60 s, network; Claude activity 5 min, no jitter, not on open, no network; Cursor limits 10 min ± 30 s, 60 s, network; Cursor activity 30 min, no jitter, 10 min, network. | Providers |
| B-31 | Timer, manual, wake and activity-changed always run; popover-opened runs when older than stale-on-open; network-restored runs when older than the interval. | Domain |
| B-32 | Single flight per task. | Application |
| B-33 | After a 429, nothing is requested from that task before `retryAt`, not even with Refresh; without `Retry-After`: 1, 2, 4… minutes up to 60; any other outcome resets. | Domain + Application |
| B-34 | Offline skips tasks that need the network. | Application |
| B-35 | The next timer fires at `retryAt` during backoff, else after interval ± jitter. | Application |
| B-36 | The timer releases itself before running, so cancelling it never cancels a request in flight. | Application |
| B-37 | Activating providers starts their tasks without waiting; deactivating cancels their timers; updates are chained in order. | Application |
| B-38 | Wake triggers a refresh 3 s later; network restored triggers one when going offline → online. | Application |
| B-39 | Opening the popover: both open signals arrive together, debounced to one within 1 s; it always lands on the usage screen. | Application + App |

### 11.5 Activity and history

| ID | Behavior | Layer |
| --- | --- | --- |
| B-40 | With the On-demand switch off, sections hide the on-demand meter; the switch only appears when an enabled snapshot has on-demand. | Domain + Application |
| B-41 | The activity window is today and the 7 days before. | Domain |
| B-42 | History rewrites the window's days on each activity refresh, freezes older days, prunes past 35 days. | Domain |
| B-43 | The week chart: 7 days ending today, zero-filled, one bar per enabled provider per day, one shared peak; empty days draw a 2 pt track mark, non-empty bars are at least 2 pt. | Domain + Components |
| B-44 | Claude log scan is incremental: only new bytes per file; a last line without newline waits for the next scan; truncated files are reread without double counting; duplicates by message key are counted once across files; unreadable lines count as diagnostics and never break the scan; files untouched since before the window are dropped. | Providers |
| B-45 | Claude scans the XDG log root first, then `~/.claude`; no root at all is `notFound`. | Providers |
| B-46 | An unreadable or old log index is discarded and rebuilt; a failed save only means a rescan next launch. | Providers |
| B-47 | Cursor tokens come from the events CSV requested only for the window; spend comes from paged usage events until a short page; a count mismatch or an event without a valid charge makes the sum unknown (no partial sums). | Providers |
| B-48 | Cursor meters: individual plans show Cursor Models and Other Models as percents (unit tokens); team/enterprise show one Included usage meter in money (unit money); on-demand appears only when enabled, with "Kicks in after included usage runs out" while unused. | Providers |
| B-49 | Claude meters: prefer `limits[]` (`session`, `weekly_all`), fall back to flat windows; a window without reset shows "No active session"; no windows at all is unexpected. | Providers |

### 11.6 Settings and app features

| ID | Behavior | Layer |
| --- | --- | --- |
| B-50 | First launch: every provider enabled, ring on, week chart on, on-demand shown. | Application |
| B-51 | Turning a provider off keeps its cache and history and stops its watcher and timers; turning it on resumes them. | Application |
| B-52 | One favorite: the heart replaces the previous one or clears it; a disabled provider can't be marked; an unknown stored id reads as no favorite and is left as is. | Domain |
| B-53 | Ring: only with the switch on, an effective favorite and a ready snapshot with meters; it follows the primary meter rounded to whole percents. | Domain |
| B-54 | VoiceOver reads "Burnie usage" or "Burnie usage, {Provider} {n}%". | Interface |
| B-55 | Header: "Updating…" before any data, "Updated just now", "Updated {n} min ago", "Updated {n} h ago"; hidden with every provider off. | Interface + App |
| B-56 | Providers screen header: "{enabled} of {total} tracking". | Interface |
| B-57 | An update shows a dot on the gear and an Update row; scheduled checks never open Sparkle's alert; a skipped version clears the dot on the next check. | Infra + App |
| B-58 | Launch at login is re-read when the providers screen appears; if approval is required, System Settings opens. | Application + Infra |

### 11.7 Security and privacy

| ID | Behavior | Layer |
| --- | --- | --- |
| B-60 | HTTP only to each provider's allowed hosts, checked before headers are sent; no redirects followed. | Infra |
| B-61 | Burnie never refreshes or rotates Claude's token; renewal runs Claude Code itself. | Providers |
| B-62 | Burnie never writes to `~/.claude`, `~/.config/claude`, the Keychain or `state.vscdb`. | Infra |
| B-63 | The renewal process gets a clean environment, a folder without `.claude/`, no tools, no user settings, no session persistence, and its output is discarded. | Providers + Infra |
| B-64 | Logs carry counts, timings and status codes only. | Infra |

---

## 12. Persistence contract

What's on disk must survive the refactor. Each item has a decoding test against a fixture with the current shape
and invented values (`T-7`).

| Data | Where | Format | Compatibility |
| --- | --- | --- | --- |
| Enabled providers | `UserDefaults` `enabledProviders` | array of provider id strings, sorted | **Must** keep. Absent = all enabled. |
| Favorite | `UserDefaults` `favoriteProvider` | provider id string | **Must** keep. Unknown id = none, key untouched. |
| Ring shown | `UserDefaults` `showRing` | bool, default true | **Must** keep. |
| Week chart shown | `UserDefaults` `showWeekChart` | bool, default true | **Must** keep. |
| On-demand shown | `UserDefaults` `showOnDemand` | bool, default true | **Must** keep (maps to `FeatureToggle.onDemand`). |
| History | `Application Support/Burnie/history.json` | `{ "<provider id>": { "yyyy-MM-dd": tokens } }` | **Must** keep: it can't be rebuilt (sources forget old days). |
| Snapshots | `Application Support/Burnie/snapshot-<provider id>.json` | `UsageSnapshot` (new shape: `content` as a `SnapshotContent` enum) | **Replaced.** The flat shape (`fetchedAt`, `plan`, `today`, `meters`) is not read back: an old file that doesn't decode reads as no cache (loading), never a crash. Costs one refresh on first launch. |
| Claude log index | `Application Support/Burnie/claude-log-index.json` | `ClaudeLogIndex` | **May** be invalidated (costs one full window rescan); never crash. |

Provider id strings (`claude`, `cursor`) and meter id strings (`session`, `weekly`, `cursorModels`, `otherModels`,
`included`, `onDemand`) are frozen: the newtypes encode exactly these raw values.

---

## 13. Decision log

| # | Date | Decision | Status |
| --- | --- | --- | --- |
| 1 | 2026-10-15 | Refactor toward a pure, functional design with an internal language inspired by category theory, starting from the domain. | Agreed |
| 2 | 2026-10-16 | Layers: Domain, Interface, Providers, Application, Infra, Components, App. | Agreed |
| 3 | 2026-10-16 | One SwiftPM module per layer, `Burnie` prefix. | Agreed |
| 4 | 2026-10-16 | Everything that is internal language lives in Domain, including favorite, ring and week chart rules. | Agreed |
| 5 | 2026-10-16 | Capabilities and features are optional data (`if let`), not protocol conformances or casts. | Agreed |
| 6 | 2026-10-16 | Two kinds of optional data: capabilities (fixed per provider) and features (per snapshot, may change with the plan). | Agreed |
| 7 | 2026-10-16 | Provider knowledge lives in one `ProviderDescriptor` per provider. | Agreed |
| 8 | 2026-10-16 | Sources are internal to each provider; the runtime schedules opaque refresh tasks. | Agreed |
| 9 | 2026-10-16 | One owner of state (Application); Domain provides pure `compose` and `merge` with laws. | Agreed |
| 10 | 2026-10-16 | Issues: common cases plus `.specific`. | Agreed |
| 11 | 2026-10-16 | Two contracts in Interface: what the UI consumes and what the runtime needs. | Agreed |
| 12 | 2026-10-16 | Use cases are what the UI calls (struct of closures, one per feature); ports are what providers and infra implement. | Agreed |
| 13 | 2026-10-16 | Infra is its own layer of dumb adapters; Sparkle, launch at login and settings move there. | Agreed |
| 14 | 2026-10-16 | The UI prefers Interface but may import Domain. | Agreed |
| 15 | 2026-10-16 | Write this spec before any code. (Bottom-up migration superseded by decision 27.) | Agreed |
| 16 | 2026-10-16 | `ProviderID` and `MeterID` become string newtypes, not enums, so switching on a provider can't compile outside its module. | Agreed |
| 17 | 2026-10-16 | `MeterSet` (non-empty, explicit primary) replaces `[Meter]` and the "first meter" convention. | Agreed |
| 18 | 2026-10-16 | `.specific` carries a code; its copy lives in the descriptor so Domain stays free of copy. | Agreed |
| 19 | 2026-10-16 | Feature toggles belong to features (Domain), not to providers: a toggle shows when some snapshot has its feature. | Agreed |
| 20 | 2026-10-16 | Application uses a pure reducer with effects (Elm-style). | Agreed |
| 21 | 2026-10-16 | Components is a SwiftPM module; provider colors come as RGB pairs from the descriptor. | Agreed |
| 22 | 2026-10-16 | Views may import Application only for `AppModel`. | Agreed |
| 23 | 2026-10-16 | Providers may keep memos (log index, hourly profile) that never change what a fresh read would show. | Agreed |
| 24 | 2026-10-16 | `Latest` and `SnapshotContent` are sum types: a success always carries its stamp, and a snapshot always has limits or today's usage. The flat snapshot cache format is dropped. | Agreed |
| 25 | 2026-10-16 | `AppState` is time-independent. Time-dependent presentation (stale, pace, "Updated n min ago") is evaluated in views with `now` from `AppModel.clock` under a `TimelineView`, not by a tick event in the reducer. | Agreed |
| 26 | 2026-10-16 | No scheduler actor: job state lives in `RuntimeState`, scheduling decisions are pure functions, timers are effects the interpreter performs with `Sleeper`. The jitter sample travels in the event. | Agreed |
| 27 | 2026-10-16 | The refactor lands in one PR, preceded by two preparatory PRs (guardrails, characterization). No ticket-by-ticket migration: nothing has to compile against half-moved code. | Agreed |

---

## 14. Delivery plan

The refactor lands in one PR (decision 27), not in tickets: nothing in between has to compile against half-moved
code, and the old modules (`BurnieCore`, `BurnieSystem`) are deleted in that same PR. Two small PRs come first,
because they are the net that proves the big one changed structure and not behavior.

### 14.1 Before · Guardrails PR

- `scripts/check-architecture.sh` with the rules of section 16.2, printing `SPEC <rule>: <file>:<line>: <message>`.
  Rules for modules that don't exist yet stay dormant until their folder appears.
- `scripts/check-sensitive.sh` (section 16.6).
- `make check` (both scripts) and `make verify` (`check` + `test` + `build`).
- `BurnieTestSupport` test-support target: `FixedClock`, `ManualSleeper`, port fakes, `Gen` (seeded property-test
  generators), fixture loading.
- Nested `CLAUDE.md` files (`@AGENTS.md`) in each module folder, excluded from targets in `Package.swift` and `project.yml`
  (section 17).
- **Done when:** `make verify` green on today's code, with the rules that apply to today's layout.

### 14.2 Before · Characterization PR

- Persistence fixtures and decoding tests for every row of section 12 (`T-7`).
- Tests for behaviors in section 11 that have none today, written against today's code (notably the store and
  scheduler: B-11, B-19, B-32…B-40, B-50, B-51). Where today's code can't be tested without a seam, add the smallest seam.
- **Done when:** every B-ID has a test, or is listed in the PR as covered manually with a reason.

### 14.3 The refactor PR

What it must contain, by module. Nothing here is sequenced: the order inside the PR is the author's.

- **Domain** (`BurnieDomain`): `BurnieCore/Domain` and the pure parts of `Refresh/`; the newtypes `ProviderID`, `MeterID`,
  `PlanName`, `Tokens`, `Cents`, `Fraction` with the frozen wire format; `MeterSet` with its primary meter; `ProviderIssue`
  common + `.specific`; `LimitsPart`, `ActivityPart`, `Stamped`, `Latest`, `SnapshotContent`, `compose`, `merge`, `failing`,
  `hiding`, `WeekChart.make`, `AppSettings`, `FeatureToggle`; every law of section 4.4 as a property test.
- **Interface** (`BurnieInterface`): ports (5.2), provider contract (5.3), use cases (5.4), app state (5.5), presentation (5.6).
  The provider switches in `BurnieCore/Format` become descriptor data; copy tests pass unchanged.
- **Providers** (`BurnieProviders`): `Claude/`, `Cursor/`, `Shared/`; each provider builds its `ProviderBundle` with
  descriptor, capabilities and tasks with policies (B-30). Claude's renewal becomes a `SignInRenewal` over `ProcessRunner`;
  the log index goes through `ProviderStorage`; scan reports go to `DiagnosticsLog`. `CompositeUsageProvider`, `UsageSource`
  and `RefreshJob` disappear. No provider type is public except its entry point.
- **Infra** (`BurnieInfra`): the adapters of section 8.2, including those moved from `App/Store`; the FSEvents watcher
  and the process runner made generic; no adapter mentions a provider.
- **Application** (`BurnieApplication`): `RuntimeState` with jobs, `Event`, `Effect`, the reducer, the interpreter with
  its timers, `Scheduling`, `AppState.derive`, `AppModel`, use cases. Every *Application* behavior in section 11 has a
  test that names its ID, with `FixedClock`, `ManualSleeper` and a fixed jitter sample, no real waiting.
- **Components** (`BurnieComponents`): the components of section 9.2, `DesignTokens`, provider colors from descriptors;
  every component has a preview and a render smoke test.
- **App**: views on `AppModel`; `App/Composition/` builds everything; previews from `AppState` values; `UsageStore`,
  `RefreshScheduler`, `PreviewScenario`'s store and `Setting` are deleted.
- **Cleanup**: `BurnieCore` and `BurnieSystem` deleted; module `AGENTS.md` files written from this spec; README's build
  section updated; final /tidy; the spec's status becomes "implemented".
- **Done when:** `make verify` green with no dormant rule left; every characterization test passes, moved to its module
  and never weakened (16.5); `make perf` within budget; the manual QA matrix (16.7) passes on a real run; the open
  questions of section 18 are answered in this file.
---

## 15. File inventory

Where every current file goes. "→ …" is the destination; notes say what changes.

### 15.1 `BurnieKit/Sources/BurnieCore`

| Current | Destination | Notes |
| --- | --- | --- |
| `Domain/ActivityReading.swift` | → Domain `ActivityPart.swift` | renamed; tokens as `Tokens`, cents as `Cents` |
| `Domain/LimitsReading.swift` | → Domain `LimitsPart.swift` | renamed; `MeterSet`, `SnapshotFeatures` |
| `Domain/ActivityWindow.swift`, `Calendar+Gregorian.swift`, `LocalDay.swift`, `DailyPoint.swift` | → Domain | `DailyPoint.value` → `tokens: Tokens` |
| `Domain/Favorite.swift`, `RingState.swift` | → Domain | ring reads `meters.primary`, `Fraction` |
| `Domain/Meter.swift`, `Meter+Pace.swift`, `MeterCaption.swift`, `MeterValue.swift` | → Domain | `Fraction`, `Cents` |
| `Domain/MeterID.swift` | → Domain | newtype; the cases move to each provider |
| `Domain/ProviderID.swift` | → Domain | newtype; `claude`/`cursor` constants move to Providers |
| `Domain/ProviderIssue.swift` | → Domain | `missingScope` → Claude `.specific` |
| `Domain/ProviderState.swift`, `TodayUsage.swift`, `UsageUnit.swift`, `UsageHistory.swift` | → Domain | |
| `Domain/UsageSnapshot*.swift` | → Domain | `content: SnapshotContent` replaces `fetchedAt`/`plan`/`today`/`meters` (kept as computed); `merge`, `failing`, `hiding`; `OnDemand` → `SnapshotFeatures` |
| `Domain/UsageSource.swift` | deleted | replaced by `PartKind` |
| `Ports/*` | → Interface `Ports/` | `SnapshotStore` splits into `SnapshotCache` and `ProviderStorage`; `SignInRenewer` → `SignInRenewal` capability over `ProcessRunner`; `UsageProvider` deleted (replaced by `ProviderBundle`) |
| `Providers/CompositeUsageProvider.swift` | deleted | logic → Domain `compose` + Application |
| `Refresh/RateLimitBackoff.swift`, `RefreshPolicy.swift`, `RefreshTrigger.swift` | → Domain | `RefreshPolicy.standard(for:)` table → each provider's tasks |
| `Refresh/RefreshJob.swift` | → Application `JobKey.swift` (internal) | keyed by provider + task name |
| `Format/*Formatter.swift`, `RingState+Label.swift` | → Interface `Presentation/` | |
| `Format/ProviderID+Display.swift`, `ProviderID+Status.swift`, `ProviderIssue+Message.swift`, `ProviderIssue+Renewal.swift`, `MeterID+Label.swift` | → descriptors in Providers + `IssueMessage`/`StatusLine` in Interface | switches become data |
| `HTTP/*`, `Parsing/ISO8601DateParser.swift`, `Cursor/CSVParser.swift`, `Cursor/Date+UnixMilliseconds.swift` | → Providers `Shared/` | `HTTPRequest` → Interface (port value) |
| `Claude/*` | → Providers `Claude/` | `ClaudeLimitsFetcher` and `ClaudeLogActivity` become task bodies; `ClaudePaths` stays provider data |
| `Cursor/*` | → Providers `Cursor/` | `CursorSummaryFetcher` and `CursorActivity` become task bodies |
| `AGENTS.md` | → split into module `AGENTS.md` files | |

### 15.2 `BurnieKit/Sources/BurnieSystem`

| Current | Destination | Notes |
| --- | --- | --- |
| `SystemClock.swift`, `URLSessionHTTPClient.swift`, `LocalFileReader.swift`, `SecurityCLIKeychain.swift`, `SQLiteKeyValueReader.swift`, `JSONFileStore.swift` | → Infra | |
| `ClaudeLogDirectoryWatcher.swift` | → Infra `DirectoryWatcher.swift` | generic over roots |
| `ClaudeCodeSignInRenewer.swift` | split | process mechanics → Infra `FoundationProcessRunner`; arguments, candidates → Providers `Claude/ClaudeSignInRenewal.swift` |
| `Providers/ClaudeProvider.swift`, `CursorProvider.swift` | → Providers entry points | take ports, not concrete adapters |
| `Providers/ProviderAssembly.swift` | deleted | replaced by `ProviderBundle` |
| `Providers/ProviderEnvironment.swift` | → composition root | |

### 15.3 `App`

| Current | Destination | Notes |
| --- | --- | --- |
| `Store/UsageStore.swift` | → Application | reducer, interpreter, `AppModel` |
| `Store/RefreshScheduler.swift` | → Application `JobState.swift`, `Scheduling.swift`, and the timer effects in the interpreter | the actor is deleted; `canRun`/`delay` become pure functions |
| `Store/UsageStore+Live.swift` | → `App/Composition/` | |
| `Store/UsageStore+Preview.swift`, `PreviewScenario.swift` | → `App/Previews/` | build `AppState` values |
| `Store/Setting.swift`, `Setting+UserDefaults.swift` | → Infra `UserDefaultsSettingsStore` | keys frozen (section 12) |
| `Store/SystemEventMonitor.swift` | → Infra `MacSystemEvents` | |
| `Store/LaunchAtLogin.swift` | → Infra `SMAppLoginItem` | |
| `Store/AppUpdater.swift` | → Infra `SparkleUpdater` | see open question 2 |
| `Views/` components (section 9.2) | → Components | |
| `Views/` views (section 10.2) | stay | read `AppModel` |
| `Views/Tokens.swift` | → Components `DesignTokens.swift` | provider colors → descriptors |
| `Assets.xcassets` `claude`, `cursor` colorsets | → descriptor `ColorPair` values | other colorsets move with `DesignTokens` |

### 15.4 Tests

| Current | Destination |
| --- | --- |
| `BurnieCoreTests/Domain`, `Refresh` | → `BurnieDomainTests` |
| `BurnieCoreTests/Format`, `ProviderIDTests.swift` | → `BurnieInterfaceTests` / `BurnieProvidersTests` (descriptor copy) |
| `BurnieCoreTests/Claude`, `Cursor`, `Fixtures` | → `BurnieProvidersTests` |
| `BurnieCoreTests/Providers` | → `BurnieDomainTests` (compose) + `BurnieApplicationTests` |
| `BurnieCoreTests/Support` | → `BurnieTestSupport` |
| `BurnieSystemTests` | → `BurnieInfraTests` |
| new | `BurnieApplicationTests`, `BurnieComponentsTests` |

---

## 16. Verification and quality control

### 16.1 Gates

Every PR runs these, in this order, and they must all pass:

| Gate | Command | Catches |
| --- | --- | --- |
| Architecture | `make check` → `scripts/check-architecture.sh` | layer, purity and naming rules (16.2) |
| Sensitive data | `make check` → `scripts/check-sensitive.sh` | secrets, real paths, emails (16.6) |
| Tests | `make test` | behavior, laws, persistence, copy |
| Build | `make build` | the app target, previews, strict concurrency |
| Performance | `make perf` (PRs that touch scanning, parsing or history) | the 200 MB log scan stays within budget |
| Tidy | /tidy skill | readability, names, nesting |
| Review | checklist (16.8) | what no tool can check |

`make verify` runs architecture, sensitive data, tests and build in one command.

### 16.2 Architecture check

`scripts/check-architecture.sh` greps the sources and fails with the rule ID, file and line. Rules:

| Rule | Check |
| --- | --- |
| G-3 | Every `import` in a module is in its allowed list (section 3.2). |
| G-4 | A file declares one top-level type, named like the file (a regex over `^(public )?(struct\|enum\|class\|actor\|protocol) `). |
| G-5 | No `case .claude`, `case .cursor`, `== .claude`, `== .cursor` outside `BurnieProviders`. |
| G-6 | No `Date()`, `Date.now`, `TimeZone.current`, `Locale.current`, `Calendar.current` outside Infra and `App/Composition`, except `TimelineView(.periodic(from: .now`. |
| G-7 | No `print(`, `NSLog(`, `debugPrint(`. |
| G-8 | No `TODO`, `FIXME`, `XXX`. |
| G-11 | No `@unchecked Sendable` outside Infra; in Infra, the line above has a comment. |
| D-2 | No `class `, `actor `, `async`, `Task`, `static var` in `BurnieDomain`. |
| D-3 | No `FileManager`, `URLSession`, `Process`, `UserDefaults`, `Bundle`, `ProcessInfo`, `NotificationCenter` in Domain, Interface, Providers, Application. |
| D-6 | No string literal with letters in Domain except `rawValue`s, coding keys and `Codable` error descriptions (allowlist by pattern). |
| I-2 | No `class `, `actor `, `var` at type level in `BurnieInterface` except in structs of closures. |
| P-1 | No `os.Logger`, `Logger(` in Providers. |
| A-1 | Only `AppModel` and `AppEnvironment` are `public` in Application. |
| C-4 | No `Color(red:`, `Color(hex`, `#colorLiteral`, numeric `.frame(width: <number>` in Components and views. |
| C-5 | No `Text("…")` with a letter literal in Components or views; copy comes from `Copy` or parameters. |
| V-3 | `import BurnieInfra` only under `App/Composition/`; `import BurnieProviders` only there and under `App/Previews/`. |

The script is plain bash and `grep`, has no dependencies, and its own test (`scripts/check-architecture-test.sh`)
runs it over a folder of deliberately bad sample files that must each fail with the expected rule ID.

### 16.3 Test strategy per module

| Module | Kind | Notes |
| --- | --- | --- |
| Domain | unit + property | every law of 4.4; every Domain B-ID; no fakes needed |
| Interface | unit | exact copy for every formatter and message, locales passed in |
| Providers | unit with fixtures and port fakes | every DTO fixture; every Providers B-ID; HTTP status classification table |
| Application | unit over the reducer + scheduler with `FixedClock`, `ManualSleeper`, fake bundles | every Application B-ID; event → effects tables |
| Infra | integration on the real macOS APIs, in temporary directories | permissions, atomic writes, host allowlist, process environment |
| Components | render smoke | each component renders with each scenario's values without crashing (`ImageRenderer`), non-zero size |
| App | build + previews + manual QA | previews compile in `make build`; manual matrix (16.7) |

Test rules (`T-*`):

- **T-1** Swift Testing only (`import Testing`), `#expect`/`#require`.
- **T-2** One test file per type under test, named `<Type>Tests.swift`.
- **T-3** A test that pins a catalog behavior has the ID first in its name: `@Test("B-17 a snapshot without meters keeps the cached ones")`.
- **T-4** No real time: `FixedClock` and `ManualSleeper`. No real network. Real disk only in Infra tests, in temp dirs.
- **T-5** No `sleep`, no polling, no retries in tests.
- **T-6** Fixtures keep the real shape with invented values: no real tokens, emails, ids, paths, account dates or usage.
- **T-7** Persistence fixtures (section 12) are never edited once written; a format change adds a new fixture.
- **T-8** Property tests use `Gen` with fixed seeds (`@Test(arguments: Gen.seeds(200))`) so failures reproduce;
  the failing seed is printed in the expectation message.
- **T-9** Components render tests live in `BurnieComponentsTests` and run under `make test`.

### 16.4 Property tests

`BurnieTestSupport/Gen` is a small seeded generator (SplitMix64) with combinators: `int(in:)`, `double` (including
NaN, ±∞, negatives, > 1), `date(around:)`, `localDay(around:)`, `meter`, `meterSet`, `snapshot`, `latest`,
`issue`, `providerID(from:)`. Each law in 4.4 is one parameterized test over 200 seeds. No third-party library.

### 16.5 Characterization and equivalence

Before code moves (the characterization PR), today's behavior is pinned by tests against today's code. In the refactor PR, those tests move with
the code and keep passing; a test may be renamed or retargeted, never weakened. When a function is replaced
(`CompositeUsageProvider` → `compose`), the old and new are both run over the full input table in the PR that
replaces it, and the PR shows that the outputs match.

### 16.6 Sensitive data check

`scripts/check-sensitive.sh` scans the staged diff (and, with `--all`, the tree) and fails on:

- absolute home paths (`/Users/<name>/`, `/home/<name>/`);
- email addresses other than GitHub noreply addresses;
- token-like strings: `sk-ant-`, `Bearer ` followed by a long token, JWT-shaped strings (`eyJ…\.…\.…`) outside the
  fixture allowlist (fixtures with invented JWTs are listed by path in the script);
- private key headers (`-----BEGIN … PRIVATE KEY-----`), `.p8`, `.p12` files;
- certificate hashes (40-hex strings next to `codesign` or `identity`).

It never prints a matched value, only the file, line and rule. Reading `git diff --cached` by eye before every commit
stays mandatory (root `AGENTS.md`).

### 16.7 Manual QA matrix

For PRs that change what the UI shows (the refactor PR, and any view change). Run `make run`, or use the matching preview when the
state can't be reproduced live. Each row is checked in light and dark mode.

| Scenario | Expect |
| --- | --- |
| ready (both providers) | both sections, meters with pace ticks, today's usage, week chart, footer links |
| first launch | placeholders with "—", "Updating…" |
| Claude not found / Cursor not found | issue row only, correct copy |
| Claude sign-in expired | cached data dimmed after 30 min, issue row, "Refresh sign-in" if `claude` is installed |
| Claude missing scope | today's tokens, no meters, specific copy |
| Claude logs unreadable | meters, no today's usage |
| Cursor session expired | cached data, issue row, no renewal button |
| Cursor enterprise | Included usage in money, today's spend in money |
| rate limited / offline | cached data, no issue row, header shows age |
| unexpected response | generic copy |
| all off | empty state with a button to the providers screen; header has no "Updated" |
| week chart hidden / on-demand hidden | chart gone / on-demand meter gone, switch still present |
| favorite marked / only one on / ring off | ring follows the right provider / implicit favorite / flame alone |
| update available | dot on gear, Update row |
| VoiceOver | menu bar label, meters combined, icon buttons labeled |

### 16.8 Review checklist

The PR body lists the rule IDs it touched and answers these:

1. Does every new concept appear in the glossary, with the same name in code?
2. Is every new type in the right module, alone in its file, with the minimum access level?
3. Are invalid states unrepresentable, or is the fallback documented and tested?
4. Does every algebraic operation have its laws tested?
5. Did any behavior in section 11 change? If so, is it a spec change in its own PR?
6. Is anything persisted read with the frozen format?
7. No provider knowledge outside `BurnieProviders`, no I/O outside Infra, no state outside Application?
8. No sensitive data (diff read by eye)?
9. Did /tidy run, and are `make verify` and, if relevant, `make perf` green?

### 16.9 Definition of done (every PR)

- Scope matches its PR in section 14; nothing extra.
- `make verify` green; `make perf` green if scanning, parsing or history changed.
- /tidy pass.
- New or moved behavior has tests named by B-ID; laws have property tests.
- Glossary and inventory updated if names or locations changed.
- Review checklist answered in the PR body.

---

## 17. How agents discover the rules

Agents should hit the right rule without being told:

1. **Entry point.** `CLAUDE.md` imports `AGENTS.md`; `AGENTS.md` says that any work on layers, names or the refactor
   starts by reading this file, and lists the rule-ID prefixes.
2. **Nested instructions.** Each module folder has an `AGENTS.md` with its rules (copied from its section here, with
   the IDs) and a `CLAUDE.md` containing `@AGENTS.md`, so agents that load nested `CLAUDE.md` files get the module's
   rules as soon as they read a file there (added in the guardrails PR; both files excluded from build targets).
3. **Failing checks teach.** Every failure of `make check` prints the rule ID and a one-line fix, so an agent that
   breaks a rule is pointed back to this file.
4. **Test names carry IDs.** A failing test named `B-17 …` points to the behavior it protects.
5. **Glossary first.** Before naming anything, search section 2. A name that isn't there is a spec change (`G-2`).
6. **Escalation.** When a rule and the task conflict, agents stop and ask once, with every conflict batched (`G-1`).

---

## 18. Open questions

1. **Sparkle in a SwiftPM module.** `BurnieInfra` would depend on Sparkle through SwiftPM while the app embeds the
   framework. If Xcode can't unify both references into one embedded copy, `SparkleUpdater` stays in
   `App/Composition/` instead. Verified in the refactor PR; a cheap spike before it is welcome.
2. **Newtypes for IDs (decision 16).** Losing `CaseIterable` means "all providers" comes from the registry. The nine
   `ProviderID.allCases` uses in today's `App/` all become reads of the registry order in `AppState.providers`.
3. **Copy localization.** Copy stays English-only. If Burnie is ever localized, `Copy` becomes the single place to
   change; not in scope.
4. **Components module and assets.** Moving the non-provider colorsets into `BurnieComponents` resources means
   `Color(_:bundle: .module)`. Fine on macOS 14; confirmed in the refactor PR.
