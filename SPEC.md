# Burnie architecture spec

The target architecture for Burnie's refactor, the internal language it is written in, the behavior it must keep,
the migration that gets there, and how every step is verified.

- **Status:** agreed design, implementation not started. Section 13 records every decision, all agreed. The open
  questions in section 18 are verified during implementation, not before.
- **Audience:** humans and agents. Every rule has an ID (`D-3`, `A-7`…) so that reviews, commit messages and the
  architecture check can point at it.
- **Precedence:** this file wins over the module `AGENTS.md` files for anything about layers, names and
  verification, during the refactor and after it (those files point here; section 17). The root `AGENTS.md` rules
  (cleanliness first, no sensitive data, read-only over other apps) stay in force and are never relaxed by this spec.
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
| **Provider copy** | The provider's own user-visible text: not found, sign-in expired, its specific issues, and its healthy status line. | `ProviderCopy` | Interface |
| **Status context** | What the healthy status line is built from: the plan, if known, and the source location, if any. | `StatusContext` | Interface |
| **Dashboard link** | A title and a URL, for the footer's dashboard item. Not `Link`, which SwiftUI already names. | `DashboardLink` | Interface |
| **Color pair** | A provider's accent as light and dark RGB values (`RGB`: red, green, blue in 0…1); Components turns it into a `Color`. | `ColorPair`, `RGB` | Interface |
| **Sign-in renewal** | A capability: a closure the provider builds that runs its own app to renew the sign-in and reports whether it worked, and the copy shown when it didn't. | `SignInRenewal` | Interface |

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
| **On-demand** | Spend past the included usage, when the plan has it on. A *feature* of a snapshot, drawn after the meter set. | `SnapshotFeatures.onDemand: Meter?` | Domain |
| **Snapshot features** | What a snapshot carries besides its meter set, each optional (today only on-demand). Travel inside the limits part. | `SnapshotFeatures` | Domain |

### 2.3 Reading and composing

| Term | Definition | Type | Module |
| --- | --- | --- | --- |
| **Source** | What a provider reads to build a part: an API, a log folder, a database. Internal to the provider: no type outside its folder names one. | — (inside each provider) | Providers |
| **Part** | One piece of information a provider reports, with its data: a limits part or an activity part. *How* and *where* a provider gets it is its own business. | `Part` (`.limits(LimitsPart)` / `.activity(ActivityPart)`) | Domain |
| **Part kind** | Which of the two parts a refresh task yields, without the data. | `PartKind` (`.limits` / `.activity`) | Domain |
| **Provider parts** | The latest limits and the latest activity of one provider, each optional until it first arrives. | `ProviderParts` (`Latest<LimitsPart>?`, `Latest<ActivityPart>?`) | Application |
| **Limits part** | Plan, meter set, usage unit and features, as of one moment. A snapshot carries it stamped, as one value, which is what merge keeps; its unit survives in the cache, so today's usage keeps it across launches (B-8). | `LimitsPart` | Domain |
| **Activity part** | Tokens per local day and, when the provider can add it up exactly, cents per local day. | `ActivityPart` | Domain |
| **Outcome** | The result of one refresh task: a part, or an issue. | `Result<Part, ProviderIssue>` | Domain |
| **Stamped** | A value and the moment it arrived. | `Stamped<Value>` | Domain |
| **Latest** | The most recent outcome of a part kind: a stamped success, or a failure with its moment and the last stamped success, if any. A sum type: a success never lacks its own stamp. | `Latest<Value>` | Domain |
| **Snapshot** | What the UI shows for a provider: its content and a partial issue. Its features are those of its limits part. | `UsageSnapshot` | Domain |
| **Snapshot content** | What a snapshot is made of: a stamped limits part with today's usage if known, or a stamped today's usage alone. A sum type: a snapshot with neither can't be built, and `fetchedAt` is the stamp of whichever case it is. | `SnapshotContent` | Domain |
| **Compose** | Pure function from the latest limits and activity to a snapshot or an issue, never to loading. | `UsageSnapshot.compose(…) -> Result<UsageSnapshot, ProviderIssue>` | Domain |
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
| **Today** | The local day of the latest event, which the interpreter computes from `Clock` and puts in every event. What compose, history and the week chart count as today. | `RuntimeState.today: LocalDay` | Application |

### 2.6 Refresh

| Term | Definition | Type | Module |
| --- | --- | --- | --- |
| **Refresh task** | One opaque job a provider declares: it yields one part and has its own policy. The runtime schedules it without knowing what it reads. | `RefreshTask` | Interface |
| **Refresh policy** | A task's interval, jitter, staleness on popover open, and whether it needs the network. | `RefreshPolicy` | Domain |
| **Trigger** | Why a refresh is requested: timer, popover opened, manual, wake, network restored, activity changed. | `RefreshTrigger` | Domain |
| **Backoff** | The wait after a 429: `Retry-After`, or 1, 2, 4… minutes up to 60. | `RateLimitBackoff` | Domain |
| **Activity watcher** | Something that reports when local activity changes (FSEvents over Claude's logs). | `ActivityWatcher` port | Interface |
| **Job** | One refresh task of one enabled provider as the runtime tracks it: its part kind, its policy, the run in flight, when it last ran, and its backoff. | `JobKey`, `JobState` in `RuntimeState.jobs` | Application |
| **Run ID** | Identifies one run of a job. Drawn from a counter in `RuntimeState`, never reused, so an outcome from a run that no longer counts (its provider was turned off, or off and on) is recognized and dropped. | `RunID` (newtype over `Int`) | Application |
| **Single flight** | At most one run of a job at a time. The reducer marks the run in the same step that asks for it. | `JobState.running: RunID?` | Application |
| **Timer ID** | Identifies one armed timer of a job. Drawn from a counter in `RuntimeState`, never reused, so a `timerFired` already on its way when its timer was cancelled or replaced is recognized and dropped. | `TimerID` (newtype over `Int`), `JobState.timer: TimerID?` | Application |
| **Sleeper** | The only way the runtime waits: `sleep(for:)`, which tests drive by hand. | `Sleeper` port | Interface |
| **Refresh request** | One use case call that refreshes (the Refresh button, opening the popover, a sign-in renewal) and the runs it started. Open until all of them finish; the Refresh spinner shows while any is open. | `RequestID`, `PendingRequest` in `RuntimeState.requests` | Application |
| **Memo** | A provider's private state that only avoids repeated work (the log index, the hourly profile plan). Losing it only costs time (`P-5`). | an `actor` inside the provider | Providers |
| **Scheduling** | The pure decisions over a job: whether a trigger runs it now, and how long until its next timer. | `Scheduling.canRun`, `Scheduling.delay` | Application |

### 2.7 Settings and the menu bar

"Feature" always means a snapshot feature (2.8). What the user can do is a use case.

| Term | Definition | Type | Module |
| --- | --- | --- | --- |
| **Favorite** | The provider the user marked with the heart. Stored only when marked; at most one. | `ProviderID?` in settings | Domain |
| **Effective favorite** | The stored favorite if it's enabled, else the only enabled provider, else none. Never stored. | `Favorite.effective` | Domain |
| **Ring** | The menu bar icon's ring: the effective favorite's primary meter, in whole percents. Hidden when off, no favorite or no meters. | `RingState` | Domain |
| **Feature toggle** | A user switch that hides a snapshot feature (today: on-demand). Shown only when some enabled snapshot has the feature. | `FeatureToggle` | Domain |
| **Settings** | What the app remembers between launches: enabled, favorite, ring shown, week chart shown, feature toggles. | `AppSettings` | Domain |
| **Setting change** | One setting the user changed, with its new value. The settings store writes only that key, so a key the user never touched stays absent and keeps its default (section 12). | `SettingChange` | Interface |
| **Launch at login** | Whether macOS opens Burnie at login. Owned by macOS, read on demand. | `LoginItem` port | Interface |
| **Login item status** | What macOS reports for launch at login: enabled, disabled, or waiting for the user's approval in System Settings. | `LoginItemStatus` | Interface |
| **Update** | A newer Burnie on the release feed. | `availableUpdate: String?` | Interface |

### 2.8 Architecture terms

| Term | Definition | Where |
| --- | --- | --- |
| **Capability** | Something a provider *can do*, fixed when it's assembled (renew sign-in, has a source location). Optional field of `ProviderCapabilities`. | Interface |
| **Provider capabilities** | The struct of a provider's capabilities, one optional field each. | Interface (`ProviderCapabilities`) |
| **Provider ports** | What one provider's entry point takes: the ports it uses (its storage and its log come already bound to its id), the values it needs (home, user name, user agent) and the factories for ports built from its own data (allowed hosts, watched directories, allowed executables). | Providers (`ClaudePorts`, `CursorPorts`) |
| **Feature** | Something a snapshot *carries*, which may change with the plan (on-demand meter). Optional field of `SnapshotFeatures`. | Domain |
| **Port** | A protocol for an effect the core needs (clock, HTTP, files, Keychain…). | Interface |
| **Process runner** | The port that runs an allowlisted executable with fixed arguments and returns its exit status. | Interface (`ProcessRunner`) |
| **Diagnostics** | What a provider or the runtime records for debugging: an event name and its measures (counts, bytes, seconds, status codes). Names are compile-time strings and values are numbers, so nothing else can reach the log. | Interface (`DiagnosticsLog`, `Measure`) |
| **Adapter** | The macOS implementation of a port. Dumb: no business rules. | Infra |
| **Use case** | One thing the user can do, as the UI calls it. A struct of one closure. | Interface |
| **Use cases** | All the use cases together, one field each, so previews and tests replace them with no-ops or recorders. | Interface (`UseCases`) |
| **App state** | The pure value the views render. | Interface |
| **Provider panel** | One provider as the views see it: descriptor, enabled, effective favorite, its state after feature toggles, and its capabilities flattened. | Interface (`ProviderPanel`) |
| **HTTP request** | The value a provider hands the HTTP port: method, URL, headers, body. Never a `URLRequest`. | Interface (`HTTPRequest`) |
| **HTTP response** | What the HTTP port returns: status, headers (looked up case-insensitively), MIME type, body. Never an `HTTPURLResponse`. | Interface (`HTTPResponse`) |
| **HTTP failure** | Why the HTTP port got no response: offline (any URL loading error: no network, timeout…), or another error. | Interface (`HTTPFailure`) |
| **App environment** | What the composition root hands Application: every port and the provider bundles. | Application (`AppEnvironment`) |
| **Runtime state** | Everything Application knows: the registry, settings, parts, what is shown, history, jobs and open requests. Only the reducer changes it. | Application (`RuntimeState`) |
| **Registered provider** | What the reducer keeps of a bundle: its descriptor, its renewal's failed copy if it can renew sign-in, its source location, and its tasks as name, part kind and policy. No closures; those stay with the interpreter. | Application (`RegisteredProvider`, `RegisteredTask`) |
| **Interpreter** | The one piece that performs effects: it calls ports, holds the live timer tasks and the use cases' continuations, and feeds results back as events. | Application |
| **App model** | The observable holder of the app state and the use cases; the only Application type the views see. | Application |
| **Event** | Something that happened that may change state. | Application |
| **Effect** | Something the reducer asks the runtime to perform. | Application |
| **Reducer** | Pure function `(State, Event) -> (State, [Effect])`. | Application |
| **Composition root** | The single place that builds adapters, providers and the app model, and connects them. | App target |
| **Component** | A SwiftUI view that takes values and closures and knows nothing about the app model. | Components |
| **Design tokens** | The colors, fonts and measurements every component uses. Provider colors aren't here; they come from descriptors. | Components (`DesignTokens`) |
| **Preview values** | The invented descriptors, snapshots and copy that component previews use (`#if DEBUG`), never a real provider's. | Components (`PreviewValues`) |
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
| App target, previews (`App/Previews/`, `DEBUG`) | as views, plus `BurnieProviders` for each provider's `descriptor` (P-3) | `Infra` |
| `BurnieTestSupport` (linked only by test targets) | `Foundation`, `BurnieDomain`, `BurnieInterface` | `Testing`, every other Burnie module, SwiftUI, AppKit |
| `<Module>Tests` | `Testing`, `BurnieTestSupport`, its module (`@testable import` only of it), and what its module may import | any other module's internals |

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
- **G-4** One top-level type per file, named like the file. Extensions are `Type+Topic.swift`. A private helper
  that only one type uses becomes a nested type of it (`URLSessionHTTPClient.RedirectRefusal`), so it stays private;
  a helper two types use gets its own file.
- **G-5** No `switch` on a provider and no comparison with a specific `ProviderID` outside `BurnieProviders`.
  The compiler enforces it for the `ProviderID` constants (`.claude`, `.cursor`), which are `internal` to Providers;
  the script catches raw strings (`"claude"`, `ProviderID(rawValue: "cursor")`).
- **G-6** No `Date()`, `Date.now`, `.now` as an implicit member (`fetchedAt: .now`), `Date(timeIntervalSinceNow:)`,
  `.timeIntervalSinceNow`, `ContinuousClock.now`, `SuspendingClock.now`, `TimeZone.current`, `Locale.current`,
  `Calendar.current` outside `BurnieInfra` (and its tests, which exercise the real APIs) and the composition root.
  Time comes from `Clock`; the time zone comes in the events (`today`) or as a parameter; views take the locale from
  SwiftUI's `@Environment(\.locale)` and pass it to formatters. The exceptions only pace drawing, inside Components
  and views: the start of a SwiftUI `TimelineView` schedule (`.periodic(from: .now, …)`) and a component's own
  animation in `IconButton` (`Spin(startingAt: .now)`, `spin?.stop(at: .now)` and the wait for it to end). The values
  drawn still take `now` from the app model's clock.
- **G-7** No `print`, `NSLog` or `debugPrint` in sources or the app. Diagnostics go through the `DiagnosticsLog` port.
  Tests may print only in the performance test, which reports its timings.
- **G-8** No `TODO`, `FIXME`, `XXX`, commented-out code or unused declarations.
- **G-9** No force unwrap or `try!` outside tests, except on values that are compile-time constants
  (a literal URL, a fixed time zone identifier) or a call that can't fail for the values involved (encoding a struct of
  plain fields), with a comment on the line above saying so.
- **G-10** Public API is the minimum the next layer needs. Default to `internal`.
- **G-11** Swift 6 strict concurrency stays `complete`. No `@unchecked Sendable` outside `BurnieInfra` and the test
  targets (port fakes), and there only with a comment naming what serializes the state.
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
  tested wire format (section 12). Newtypes encode as their single raw value, never as a keyed object.
- **D-5** Functions are total: no `fatalError`, no `precondition` on inputs. An invalid input is unrepresentable
  (type) or mapped to a defined value (clamp, nil) that is documented.
- **D-6** No user-visible strings. Copy lives in `BurnieInterface`.
- **D-7** Every algebraic operation has its laws listed in section 4.4 and a property test.
- **D-8** Nothing provider-specific: no Claude or Cursor names, meter IDs, URLs or plan names.

### 4.2 Types

Sketches. Names are binding; exact signatures are settled in the PR that writes them, without changing meaning.

```swift
// Identity (every newtype encodes as its bare raw value: a string or a number)
struct ProviderID: RawRepresentable, Hashable, Codable, CodingKeyRepresentable, Sendable { let rawValue: String }
struct MeterID: RawRepresentable, Hashable, Codable, Sendable { let rawValue: String }
struct PlanName: RawRepresentable, Hashable, Codable, Sendable { let rawValue: String }

// Quantities (single-value Codable: `Tokens` encodes as `1250000`, never `{"count": 1250000}`)
struct Fraction: Hashable, Codable, Sendable, Comparable { let value: Double }   // init and decoding clamp to 0…1, NaN → 0
struct Tokens: Hashable, Codable, Sendable, Comparable, AdditiveArithmetic { let count: Int }
struct Cents: Hashable, Codable, Sendable, Comparable, AdditiveArithmetic { let amount: Int }

// Meters
struct Meter { let id: MeterID; let fill: Fraction; let value: MeterValue; let caption: MeterCaption; let period: DateInterval? }
enum MeterValue { case percent(Int); case money(used: Cents, limit: Cents?) }
enum MeterCaption { case resetsIn(Date), resetsAt(Date), cycleEnds(Date), noActiveSession, onDemandIdle }
struct MeterSet { let primary: Meter; let others: [Meter] }      // non-empty; `all` = [primary] + others;
                                                                 // init?(_ meters: [Meter]) is nil only for []

// Snapshot
enum UsageUnit { case tokens, money }
enum TodayUsage { case tokens(Tokens), money(Cents) }
struct SnapshotFeatures { var onDemand: Meter? }
struct Stamped<Value> { var value: Value; var at: Date }
enum SnapshotContent {
    case limits(view: Stamped<LimitsPart>, today: TodayUsage?)   // today nil if activity failed or never loaded
    case activityOnly(Stamped<TodayUsage>)                       // limits failed or never loaded
}
struct UsageSnapshot {
    var provider: ProviderID
    var content: SnapshotContent
    var issue: ProviderIssue?    // partial issue; persisted with the snapshot, as today
    // Computed, for views and formatters: fetchedAt (the content's stamp), plan, meters, unit, features (none when
    // `.activityOnly`), today.
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
struct LocalDay              // as today; Strideable, Codable as "yyyy-MM-dd", CodingKeyRepresentable (a JSON key)
enum ActivityWindow          // dayCount = 8; days(endingAt:)
struct DailyPoint { var day: LocalDay; var tokens: Tokens }
struct UsageHistory          // record(_ tokens:for:today:), points(for:endingAt:count:); retentionDays = 35
struct WeekChart { let days: [LocalDay]; let providers: [ProviderID]; let series: [ProviderID: [Tokens]]; let peak: Tokens }

// Refresh
struct RefreshPolicy { let interval: TimeInterval; let jitter: TimeInterval; let staleOnOpen: TimeInterval?; let needsNetwork: Bool }
enum RefreshTrigger { case timer, popoverOpened, manual, wake, networkRestored, activityChanged }
struct RateLimitBackoff      // as today

// Settings and the menu bar
enum Favorite                // effective(stored:enabled:), toggling(_:stored:enabled:), ring(…)
enum RingState { case hidden, visible(ProviderID, percent: Int) }   // the primary meter's fill, rounded, 0…100
enum FeatureToggle: CaseIterable { case onDemand }              // the settings store maps each to its key (section 12)
struct AppSettings { var enabled: Set<ProviderID>; var favorite: ProviderID?; var showRing: Bool;
                     var showWeekChart: Bool; var hiddenFeatures: Set<FeatureToggle> }
```

### 4.3 Pure operations

| Operation | Meaning | Replaces |
| --- | --- | --- |
| `UsageSnapshot.compose(provider:limits:activity:today:cachedUnit:)` | From the latest limits and activity to `Result<UsageSnapshot, ProviderIssue>`: a snapshot, or the issue of a total failure (B-14). It can't return loading. Today's usage reads in the unit of the latest successful limits; before any since launch, in `cachedUnit` (the shown snapshot's unit), and tokens without one (B-7, B-8). A failed limits never contributes its `lastSuccess` meters: those come back through merge. Rules B-10…B-16. | `CompositeUsageProvider.composedSnapshot` |
| `Latest.recording(_ outcome:, at:)` | A success becomes `.success(stamped)`; a failure becomes `.failure` carrying the previous `lastSuccess`. Rule B-8. | the `unit` variable in `CompositeUsageProvider` |
| `UsageSnapshot.merge(_ previous:, _ next:)` | When `next` is `.activityOnly` and `previous` is `.limits`, the result is `previous`'s stamped limits part (plan, meters, unit and features) with `next`'s today's usage and issue; otherwise `next`. Rule B-17. | `keepingMeters(of:)` |
| `ProviderState.failing(_ issue:, previous:)` | A total failure over a cached snapshot becomes `.ready(previous with issue)`; without one, `.failed(issue)`. Rule B-18. | `with(issue:)` + store code |
| `UsageSnapshot.hiding(_ toggles:)` | Removes hidden features from the limits part. Rule B-40. | `hidingOnDemand()` |
| `UsageHistory.record(_ tokens:for:today:)` | Writes every day of the activity window ending `today`, 0 for the days `tokens` doesn't mention; prunes that provider's days past retention and leaves every other provider untouched, as today. `today` is the event's day: a part read just before midnight lands one day short, and the next refresh corrects it. Rule B-42. | `history(days:)` + `record` |
| `WeekChart.make(history:providers:today:)` | 7 days ending today, zero-filled, shared peak. | logic in `WeekChart` view |
| `Favorite.*`, `RingState` | As today, with the ring reading `meters.primary` as a whole percent. | `meters.first` |
| `RefreshPolicy.shouldRun(for:lastRun:now:)` | As today. | same |
| `RateLimitBackoff.*` | As today. | same |

### 4.4 Laws

Each law is a property test in `BurnieDomainTests` (section 16.4). `≡` means equal by `Equatable`.

- **Fraction**: `Fraction(x).value ∈ [0, 1]` for every `Double` including ±∞ and NaN; `Fraction(Fraction(x).value) ≡ Fraction(x)` (idempotent clamp).
- **Tokens / Cents**: `AdditiveArithmetic` laws: associativity, commutativity, `.zero` identity, over `Gen`'s range
  (0…10¹²). Addition saturates at `Int.max` instead of trapping (D-5); no real usage gets near it.
- **Latest**: `recording(.success(v), at: t).lastSuccess ≡ Stamped(v, t)`; `recording(.failure(e), at: t).lastSuccess ≡ lastSuccess`
  (a failure never loses the last success); `recording(.failure(e), at: t).issue ≡ e`.
- **Merge** (a semigroup: "last snapshot with limits wins the limits"):
  - associativity: `merge(merge(a, b), c) ≡ merge(a, merge(b, c))`
  - idempotence: `merge(a, a) ≡ a`
  - right-biased: if `b.content` is `.limits` then `merge(a, b) ≡ b`
  - `today` and `issue` always come from the right.
  - the limits part is never split: plan, meters, unit and features of the result all come from the same side.
- **MeterSet**: `s.all.first ≡ s.primary`; `s.all.count == s.others.count + 1`; `MeterSet(s.all) ≡ s`;
  `MeterSet(ms)` is nil exactly when `ms` is empty.
- **Compose**: total over every combination of `Latest<LimitsPart>?` × `Latest<ActivityPart>?` (nil, success, failure).
  (That the result never shows neither meters nor today's usage is now guaranteed by `SnapshotContent`, not by a law.)
- **Failing**: `failing(e, previous: s) ≡ .ready(s with issue e)`, so the content of `s` is never lost;
  `failing(e, previous: nil) ≡ .failed(e)`.
- **Hiding**:
  - identity: `s.hiding([]) ≡ s`
  - idempotence: `s.hiding(t).hiding(t) ≡ s.hiding(t)`
  - composition: `s.hiding(a).hiding(b) ≡ s.hiding(a ∪ b)`
  - commutes with merge: `merge(a, b).hiding(t) ≡ merge(a.hiding(t), b.hiding(t))`
  - only features change: the meter set, today's usage, the issue and the stamp are untouched.
- **WeekChart**: `days` are 7 consecutive local days ending today; `series[p].count == 7` for every `p` in
  `providers`, which keep the order they were given; `peak` is the largest value of every series, `.zero` when all are
  zero.
- **Favorite**: when `id ∈ e`, `toggling(id, s, e)` is nil if `s == id`, else `id`; so tapping twice gives back `s` when
  `s` is nil or `id`, and nil when `s` was another provider (the first tap replaced it). `effective` result is always
  in `enabled` or nil; toggling a disabled provider is the identity.
- **LocalDay**: `d.advanced(by: n).advanced(by: -n) ≡ d`; `d.distance(to: d.advanced(by: n)) == n`;
  `LocalDay(iso: d.iso) ≡ d`; ordering agrees with `distance`.
- **UsageHistory**: `record(p)` twice ≡ once (idempotent); after `record(p, for: id)`, no day of `id` older than
  retention remains, every day of the window has a value (0 if `p` didn't mention it), and every other provider's
  days are unchanged; `points(count: n)` has `n` consecutive days ending today for `n ≥ 1`, and is empty for `n ≤ 0`
  (D-5: never a reversed range).
- **RingState**: `visible` percent is in 0…100 and equals the primary meter's fill × 100, rounded.
- **RateLimitBackoff**: without `Retry-After`, waits are non-decreasing across consecutive 429s and capped at 60
  minutes; with it, `retryAt` is exactly the server's date, whatever its length; `reset` returns to the initial value.
- **Codable**: `decode(encode(x)) ≡ x` for every persisted type; every newtype encodes to its bare raw value.
- **Scheduling** (in `BurnieApplicationTests`, since `Scheduling` lives in Application): for every trigger,
  `canRun` is false while the job is running or before its backoff's `retryAt`, and false when offline for a policy
  that needs the network; `delay` is never negative, is `retryAt − now` during backoff, and otherwise lies in
  `interval ± policy.jitter`, equal to `interval` for a jitter sample of 0.

---

## 5. Interface (`BurnieInterface`)

The contract between the UI, the runtime and the providers. Types, protocols and pure presentation; no state.

### 5.1 Rules (`I-*`)

- **I-1** Imports only `Foundation` and `BurnieDomain`.
- **I-2** No shared mutable state: no `class`, no `actor`, no `static var`, no global `var`. `var` fields of structs
  are fine: they are values (`AppState`, `ProviderPanel`, `ProviderCapabilities`).
- **I-3** A type here that is identical to a domain type is deleted (the domain type is used instead).
- **I-4** Every capability is an optional field of `ProviderCapabilities`; every snapshot feature is an optional field
  of `SnapshotFeatures` (domain). Adding one is a spec change.
- **I-5** Ports are the minimum an adapter must do. A port never exposes a macOS type, nor Foundation's networking
  types (`URLRequest`, `HTTPURLResponse`, `URLError`).
- **I-6** Use cases are what the UI calls; ports are what providers and infra implement. A provider never implements
  a use case; a view never calls a port. The one exception is reading `AppModel.clock.now` for time-dependent
  presentation (A-6).
- **I-7** All copy lives in `Presentation/`. Copy is English, sentence case, and tested for the exact text.

### 5.2 Ports

| Port | Purpose | Implemented by | Used by |
| --- | --- | --- | --- |
| `Clock` | `now`, `timeZone`. | `SystemClock` | the interpreter (to stamp events), providers, views (A-6) |
| `Sleeper` | `sleep(for:)` that tests can drive. | `TaskSleeper` | Application interpreter (timers) |
| `HTTPClient` | Send an `HTTPRequest`, get an `HTTPResponse` or throw an `HTTPFailure`. Only the hosts it was built for. | `URLSessionHTTPClient` | Providers |
| `FileReading` | List, attributes, read from offset, exists, is executable. Read-only. | `LocalFileReader` | Providers |
| `SecretReader` | Read a generic password from the Keychain. Never writes. | `SecurityCLIKeychain` | Providers |
| `KeyValueDatabase` | Read one row of a SQLite key-value table. Read-only. | `SQLiteKeyValueReader` | Providers |
| `ProviderStorage` | Load and save one provider's private JSON (Claude's log index) by name. The composition root binds it to the provider's id: `name` is stored as `<provider id>-<name>.json`, so Claude's `log-index` stays `claude-log-index.json` (section 12). | `JSONFileStore` | Providers |
| `ProcessRunner` | Run an executable from the allowlist it was built with, with fixed arguments, clean environment, no output, a timeout; return the exit status. | `FoundationProcessRunner` | Providers |
| `ActivityWatcher` | `start(onChange:)` / `stop()` over the directories it was built for. | `DirectoryWatcher` (FSEvents) | Providers (build and declare), Application (start and stop) |
| `DiagnosticsLog` | `record(_ event: StaticString, _ measures: [Measure])` under the category it was built for (the provider's id, or `app`). It takes no `String`, so a secret can't reach it (B-64). | `OSDiagnosticsLog` | Providers and the adapters their factories build, Application, the composition root (B-73) |
| `SnapshotCache` | Load and save the app's own files: snapshots and history. Synchronous; a file that doesn't decode loads as nil, and a failed save is ignored (the next one retries). | `JSONFileStore` | Application |
| `SettingsStore` | `load(defaultEnabled:) -> AppSettings` (synchronous) with the keys of section 12, where a missing key loads as its default and a missing `enabledProviders` as `defaultEnabled` (the registry's ids); `save(_ change: SettingChange)` writes only the key that changed. | `UserDefaultsSettingsStore` | Application |
| `SystemEvents` | `start(onWake:onNetworkChange:)`: wake and network reachability callbacks. | `MacSystemEvents` | Application |
| `LoginItem` | `status() -> LoginItemStatus`, `set(_ enabled:)`, `openSystemSettings()`. | `SMAppLoginItem` | Application |
| `Updater` | `start(onUpdate:)` reports the available version or nil after each scheduled check; `install()` opens the installer. | `SparkleUpdater` | Application |
| `URLOpener` | Open an external URL. | `WorkspaceURLOpener` | Application |
| `AppLifecycle` | Quit. | `NSAppLifecycle` | Application |

Port values:

```swift
struct HTTPResponse: Sendable { let status: Int; let headers: [String: String]; let mimeType: String?; let body: Data }
                                   // header(_ name:) looks up case-insensitively (`Retry-After`, B-24)
enum HTTPFailure: Error { case offline, other(String) }   // offline: any URL loading error (B-24)
enum LoginItemStatus { case enabled, disabled, requiresApproval }
enum Measure: Sendable { case count(StaticString, Int), bytes(StaticString, Int),
                         seconds(StaticString, Double), status(Int) }   // numbers only, always public in the log
enum SettingChange: Equatable, Sendable { case enabled(Set<ProviderID>), favorite(ProviderID?), ringShown(Bool),
                                          weekChartShown(Bool), featureShown(FeatureToggle, Bool) }
```

Ports whose adapter needs a provider's data (allowed hosts, watched directories, allowed executables) reach the
provider as factories in its provider ports (`P-3`), never as adapters built with that data hard-coded. The
composition root builds one provider's ports at a time, so its storage, its log and every adapter its factories make
(the HTTP client records each response's status and elapsed time, the process runner its exit status and duration)
 log through that provider's `DiagnosticsLog`, bound to its id without the provider passing it.

### 5.3 Provider contract

```swift
struct ProviderDescriptor: Sendable {
    let id: ProviderID
    let displayName: String              // "Claude Code"
    let shortName: String                // "Claude", chart legend
    let color: ColorPair                 // light and dark RGB; Components turns it into a Color
    let dashboard: DashboardLink         // title + URL for the footer
    let meters: [MeterDescriptor]        // id + label, in display order; `placeholderMeters` while loading
    let placeholderMeters: [MeterID]
    let copy: ProviderCopy               // issue rows, status lines
}

struct ProviderCopy: Sendable {
    let notFound: String
    let signInExpired: String
    let specific: [SpecificIssue: String]   // a code without copy shows the common unexpected copy
    let status: @Sendable (StatusContext) -> String   // healthy status line on the providers screen
}

struct StatusContext: Sendable { let plan: PlanName?; let sourceLocation: String? }
struct MeterDescriptor: Sendable { let id: MeterID; let label: String }
struct DashboardLink: Sendable { let title: String; let url: URL }
struct ColorPair: Sendable { let light: RGB; let dark: RGB }   // RGB: three Doubles in 0…1

struct ProviderCapabilities: Sendable {
    var signInRenewal: SignInRenewal?    // nil: Burnie can't renew this provider's sign-in
    var sourceLocation: String?          // "~/.claude", shown in the status line
}

struct SignInRenewal: Sendable {
    let run: @Sendable () async -> Bool  // true once the provider's own app renewed the sign-in
    let failedCopy: String               // the row's text when `run` returns false (B-22)
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
- Every meter id a provider's mappers can produce is in its `descriptor.meters` (a Providers test per mapper). Should
  one slip through, its label is the id's raw value, never an empty row or a crash.
- Provider ids `snapshot` and `history` are reserved: they would collide with the app's own files (section 12).

### 5.4 Use cases

Each use case is one thing the user can do, documented where it's declared. They're grouped in `UseCases`,
a struct of closures, so previews and tests replace them with no-ops or recorders.

| Use case | Signature | What it does |
| --- | --- | --- |
| `OpenPopover` | `() -> Void` | Opening the popover refreshes what's stale. Debounced 1 s. (Landing on the usage screen is the view's own route state, B-39.) |
| `RefreshUsage` | `() async -> Void` | The Refresh button: every enabled task regardless of age, except during backoff. |
| `RenewSignIn` | `(ProviderID) async -> Bool` | The expired sign-in button: the provider's app renews it, then its limits refresh. Returns false at once for a provider that is disabled or can't renew. |
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
    var weekChart: WeekChart?            // ending RuntimeState.today; nil when the switch is off or nothing is enabled
    var lastUpdated: Date?               // most recent fetchedAt among enabled providers
    var isRefreshing: Bool
    var settings: AppSettings
    var visibleToggles: [FeatureToggle]  // toggles some enabled snapshot has a feature for, read before
                                         // hiding, so turning one off keeps its switch (B-40)
    var launchAtLogin: Bool
    var availableUpdate: String?
}

struct ProviderPanel: Equatable, Sendable {
    let descriptor: ProviderDescriptor   // Equatable by id
    var isEnabled: Bool
    var isFavorite: Bool                 // effective favorite
    var state: ProviderState             // already filtered by feature toggles
    var renewalFailedCopy: String?       // nil: Burnie can't renew this sign-in
    var sourceLocation: String?
}
```

### 5.6 Presentation

Everything that turns domain values into text, moved from `BurnieCore/Format/`:
`TokenCountFormatter`, `MoneyFormatter`, `MeterValueFormatter`, `MeterCaptionFormatter`, `TodayUsageFormatter`,
`LastUpdatedFormatter`, `DayLabelFormatter`, `RingAccessibilityLabel`, `StatusLine`, `IssueMessage`, and `Copy`
(every fixed string the views show: "Usage", "Providers", "Last 7 days", "Refresh sign-in", "Quit"…).
Provider-specific text comes from `ProviderDescriptor.copy`, never from a switch. `StatusLine` (B-29) builds the
non-healthy lines as common templates over `displayName` ("Off", "{displayName} not found",
"Sign-in expired · open {displayName}"); every other state, a specific issue included, shows the provider's healthy
line (`copy.status`; Cursor's reads the chip as a name: "PRO+" → "Signed in · Pro+ plan").

---

## 6. Providers (`BurnieProviders`)

Each provider turns its sources into parts. Sources are internal (agreed): nobody outside a provider's folder knows
what it reads, how often, or in how many calls.

### 6.1 Rules (`P-*`)

- **P-1** Imports `Foundation`, `BurnieDomain`, `BurnieInterface` only. All I/O through ports.
- **P-2** Folder per provider: `Claude/`, `Cursor/`. Shared helpers in `Shared/` (HTTP fetch rules, ISO 8601, CSV,
  `Retry-After`). Nothing in `Shared/` mentions a provider.
- **P-3** Each provider exposes exactly two public members on one entry point: `enum ClaudeProvider { static let descriptor:
  ProviderDescriptor; static func bundle(_ ports: ClaudePorts) -> ProviderBundle }`. `descriptor` is pure data, so
  previews read it without ports; `bundle` hands out that same descriptor.
  `ClaudePorts` / `CursorPorts` are structs of the ports and values it needs (home, user name, user agent), plus
  factories for the ports built from the provider's own data: `makeHTTPClient(allowedHosts:)`,
  `makeWatcher(directories:)`, `makeProcessRunner(allowedExecutables:)`. Its `ProviderStorage` and its
  `DiagnosticsLog` come already bound to its id (5.2).
- **P-4** DTOs never leave their provider's folder. Mappers are pure functions from DTO to domain parts.
- **P-5** A provider may keep a **memo**: private state that only avoids repeated work (the log index, the hourly
  profile plan). A memo never decides what the UI shows beyond what a fresh read would; losing it only costs time.
  Memos live in an `actor` inside the provider and persist only through `ProviderStorage`.
- **P-6** Each provider declares its hosts and builds its `HTTPClient` with `makeHTTPClient(allowedHosts:)`; that
  client only reaches those hosts (B-60). The same goes for the executables it may run.
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
  `AppModel`'s public members are `state`, `useCases`, `clock`, `live(_:)` and, under `DEBUG`, `preview(_:)` (7.4).
- **A-2** State changes only in the reducer: `reduce(_ state: RuntimeState, _ event: Event) -> (RuntimeState, [Effect])`,
  pure and synchronous.
- **A-3** Effects are performed by one interpreter that calls ports and feeds results back as events.
  Nothing else calls a port.
- **A-4** There is no scheduler actor. Job state (`RuntimeState.jobs`) lives in the reducer; `Scheduling.canRun` and
  `Scheduling.delay` are pure functions over a `JobState`. The interpreter only holds the live timer `Task`s, which
  turn `scheduleTimer`/`cancelTimer` effects into `Sleeper` waits that come back as `timerFired` events, and the
  continuations of the use cases that await (7.3).
- **A-5** Time only from `Clock`; waiting only through `Sleeper`. Tests never wait for real time. The reducer never
  reads a clock: every event carries `now` and `today`.
- **A-6** `AppState` is derived by a pure function `AppState.derive(from: RuntimeState)`. Its only link to time is
  `RuntimeState.today`, which events advance (the week chart ends there); nothing in it changes while no event
  arrives. Views may evaluate pure functions of `(state, now)`, from `BurnieDomain` (`isStale`, `elapsedFraction`)
  and from `BurnieInterface` (formatters), with `now` from `AppModel.clock` under a `TimelineView`; they hold no
  state and make no decisions.
- **A-7** Every behavior in section 11 tagged *Application* has a test that names its ID.

### 7.2 Runtime state

```swift
struct RuntimeState: Equatable {
    let registry: [RegisteredProvider]           // registry order; built once from the bundles
    var today: LocalDay                          // the latest event's local day
    var settings: AppSettings
    var parts: [ProviderID: ProviderParts]       // Latest<LimitsPart>?, Latest<ActivityPart>?
    var shown: [ProviderID: ProviderState]       // after compose + merge, or failing; cached only after a success
    var history: UsageHistory
    var jobs: [JobKey: JobState]                 // one per refresh task of each enabled provider
    var nextRun: RunID
    var nextTimer: TimerID
    var requests: [RequestID: PendingRequest]    // open refresh requests; isRefreshing = !requests.isEmpty
    var lastPopoverOpen: Date?                   // the last popoverOpened that wasn't debounced (B-39)
    var isOnline: Bool                           // true until SystemEvents reports otherwise (B-34)
    var launchAtLogin: Bool
    var availableUpdate: String?
}

struct RegisteredProvider: Equatable {           // a bundle without its closures
    let descriptor: ProviderDescriptor           // Equatable by id
    let renewalFailedCopy: String?               // the SignInRenewal's failedCopy; nil if it can't renew
    let sourceLocation: String?
    let tasks: [RegisteredTask]
}
struct RegisteredTask: Equatable { let name: String; let part: PartKind; let policy: RefreshPolicy }

struct JobKey: Hashable { let provider: ProviderID; let task: String }   // task = RefreshTask.name
struct RunID: Hashable { let value: Int }        // from RuntimeState.nextRun, never reused
struct TimerID: Hashable { let value: Int }      // from RuntimeState.nextTimer, never reused
struct JobState: Equatable {
    let part: PartKind
    let policy: RefreshPolicy
    var running: RunID?                           // single flight (B-32): set in the step that emits runTask
    var timer: TimerID?                           // the armed timer; nil once it fired or was cancelled
    var lastRun: Date?
    var backoff: RateLimitBackoff
}

struct RequestID: Hashable { let value: Int }    // drawn by the interpreter when a use case starts
struct PendingRequest: Equatable {
    var runs: Set<RunID>                          // runs it started that haven't finished
    var isRenewing: Bool                          // RenewSignIn only: the provider's app is still running
    var result: Bool                              // what RenewSignIn returns; true for the others
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

Every event also carries `now` and `today`, which the interpreter reads from `Clock` when it sends it; the reducer
sets `RuntimeState.today` before anything else. **Start a run** of a job means: if `canRun` for the trigger, take
`nextRun`, set the job's `running` to it, add it to the event's request if there is one, set the job's `timer` to
nil, and emit `cancelTimer(key)` and `runTask(key, run)`. **Arm the timer** of a job means: take `nextTimer`, set the
job's `timer` to it, and emit `scheduleTimer(key, timer, after: delay(…))`; the interpreter replaces any live timer of
that key. A request that starts no run, or whose last run finishes, closes with `finishRequest(request, result)` once
it isn't renewing.

| Event | Reducer outcome | Effects |
| --- | --- | --- |
| `launched(settings, cached snapshots, history)` | `settings.enabled` keeps only ids in the registry (an unknown id is ignored, and dropped on the next `.enabled` save, section 12); ready states from cache, else loading; a `JobState` per task of each enabled provider. | `startSystemEvents`; `startUpdater`; `startWatcher` per enabled provider; start a run of every job with `.manual` (B-37) |
| `popoverOpened(request)` | Ignored if < 1 s since `lastPopoverOpen` (B-39); else `lastPopoverOpen = now` and opens `request`. | start a run of every job where `canRun(.popoverOpened)` |
| `refreshRequested(request)` | Opens `request`. | start a run of every job where `canRun(.manual)` |
| `taskFinished(key, run, outcome, jitter)` | Removes `run` from every request. Then dropped if `key` is gone or `run` isn't its `running` (the provider was turned off, or off and on, B-51). Else `running = nil`; `lastRun = now`; backoff recorded on 429, reset otherwise (B-33); update `Latest`; compose, with the shown snapshot's unit as `cachedUnit` (B-8): a `.success(snapshot)` is merged over the shown snapshot and shown, a `.failure(issue)` goes through `failing(issue, previous:)` (B-18); on activity success, record history (B-42). | after a compose `.success` only, `saveSnapshot(shown)` (B-19); a total failure saves nothing, so the cache keeps the last good snapshot; on activity success, `saveHistory`; arm the timer (B-35) |
| `timerFired(key, timer)` | Dropped unless `timer` is the job's `timer`; else `timer = nil`. | start a run if `canRun(.timer)`; otherwise nothing, and no new timer until another trigger runs the job (B-35) |
| `trigger(RefreshTrigger)` | — | start a run of every job where `canRun` (the wake below) |
| `woke` | — | `wait(3 s, then: .trigger(.wake))` (B-38) |
| `networkChanged(isOnline)` | `isOnline = isOnline`. | on offline → online, start a run of every job where `canRun(.networkRestored)` (B-38), and arm the timer of every other job that has neither a run nor a timer (B-35) |
| `activityChanged(id)` | — | start a run of `id`'s activity job if `canRun(.activityChanged)` |
| `providerToggled(id, isOn)` | Ignored if `id` isn't in the registry or is already in that state. Else update settings; add or remove `id`'s jobs (B-51). | `saveSetting(.enabled(settings.enabled))`; `startWatcher`/`stopWatcher`; on add start a run of the new jobs with `.manual`, on remove `cancelTimer` for the old ones (B-37) |
| `favoriteTapped(id)` | `Favorite.toggling`. | `saveSetting(.favorite(settings.favorite))` |
| `ringShownSet(Bool)` / `weekChartShownSet(Bool)` / `featureShownSet(toggle, Bool)` | Update that setting. One event per switch, so a provider or favorite change can't arrive this way. | `saveSetting(.ringShown(…))` / `.weekChartShown(…)` / `.featureShown(…)` |
| `renewRequested(id, request)` | Opens `request` as renewing if `id` is enabled and can renew; else opens nothing. | `renewSignIn(id, request)`; else `finishRequest(request, false)` |
| `renewFinished(id, ok, request)` | `isRenewing = false`; `result = ok`. | on success, start a run of `id`'s limits job if `canRun(.manual)` (B-23) |
| `launchAtLoginSet(Bool)` / `launchAtLoginReadRequested` | — | `setLaunchAtLogin(Bool)` / `readLaunchAtLogin` |
| `launchAtLoginChanged(status)` / `launchAtLoginRead(status)` | `launchAtLogin = status == .enabled`. | after a set only, `openLoginItemsSettings` if `.requiresApproval` (B-58) |
| `updateFound(String?)` | Store it (B-57). | — |
| `installUpdateRequested` / `dashboardRequested(id)` / `quitRequested` | — | `installUpdate` / `openURL(id's dashboard URL)` / `quit` |

The effects, complete: `runTask(key, run)`, `scheduleTimer(key, timer, after:)`, `cancelTimer(key)`, `wait(_:then:)`,
`startWatcher(id)`, `stopWatcher(id)`, `startSystemEvents`, `startUpdater`, `saveSnapshot(snapshot)`, `saveHistory`,
`saveSetting(SettingChange)`, `renewSignIn(id, request)`, `finishRequest(request, result)`, `setLaunchAtLogin(Bool)`,
`readLaunchAtLogin`, `openLoginItemsSettings`, `installUpdate`, `openURL(URL)`, `quit`.

`AppModel.live` loads settings (with the registry's ids as `defaultEnabled`), cached snapshots and history through
their synchronous ports and reduces `launched` before it returns (7.4). The interpreter performs
`scheduleTimer(key, timer, after:)` with a `Sleeper` wait that ends in
`timerFired(key, timer)`, and `cancelTimer(key)` by cancelling that wait; a `timerFired` already queued when its
timer was cancelled or replaced no longer matches the job's `timer` and is dropped. It performs
`runTask(key, run)` by awaiting the task's `run` and sending `taskFinished(key, run, outcome, jitter: random in -1…1)`;
because the reducer marks the run in the step that asks for it, two triggers in a row can't start a job twice (B-32).
Single flight is per job: a provider turned off and on gets new jobs, so for a moment its dropped run and the new
one may both be in flight, as today; only the new one's outcome counts (B-51).
It performs `renewSignIn(id, request)` with the provider's `SignInRenewal` and sends `renewFinished`; after
`setLaunchAtLogin` it reads the status back and sends `launchAtLoginChanged`. A use case that
awaits (`RefreshUsage`, `RenewSignIn`) draws a `RequestID`, keeps a continuation for it, sends its event, and returns
when `finishRequest` resumes it; `RenewSignIn` returns the request's `result`. `OpenPopover` opens a request too, so
the spinner shows (B-59), but nothing awaits it. Chained activation (B-37) is free: events are processed in order on
the main actor.

Invariant, checked after every event in the reducer tests: every job has a run in flight or an armed timer, except a
job whose policy needs the network while offline, which waits for `networkChanged` (B-35).

### 7.4 App model

`@MainActor @Observable final class AppModel { private(set) var state: AppState; let useCases: UseCases; let clock: Clock }`.
`clock` is for the views' `TimelineView` and for deterministic previews (A-6); previews get a fixed clock.
`AppModel.live(_ environment: AppEnvironment)` is the composition root's only way in: it loads the persisted state,
reduces `launched` and publishes the first `AppState` before returning, so the first frame already shows the cache
(never the empty "all off" state), then hands the launch effects to the interpreter. It holds `RuntimeState`
privately, runs the reducer on each event, derives `AppState`, and assigns `state` only when the derived value
differs (`@Observable` doesn't compare, so an equal value would still redraw). Previews build it with
`AppModel.preview(_ state: AppState)`, which has no-op use cases and no runtime.

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
- **X-3** Never logs or stores secrets. An adapter built by a provider's factory logs only through the `DiagnosticsLog`
  it's given. Any other adapter uses `os.Logger` with the app's subsystem and a category; numbers are public, every
  other interpolation is `.private` (error descriptions included). Never tokens, cookies, user ids, paths or response bodies.
- **X-4** Read-only over other apps' files and the Keychain. Writes only to `~/Library/Application Support/Burnie/`
  (0700 folder, 0600 files, atomic), to `UserDefaults`, and what Sparkle needs for an update the user asked for.
- **X-5** `FoundationProcessRunner` only runs executables in the allowlist it was built with (absolute paths the
  provider passes, Claude's `claude` candidates), with fixed arguments, a minimal environment (`HOME`, `USER`,
  `LOGNAME`, a system `PATH`), a working directory without `.claude/`, null stdin/stdout/stderr and a timeout.
  `SecurityCLIKeychain` runs `/usr/bin/security` itself, because it reads the password from stdout: fixed
  arguments, no stdin, stderr discarded, the output never logged.
- **X-6** SQLite opens read-only with a timeout; if busy, copies the database and its WAL to a private 0700 temporary
  directory, reads the copy and deletes it in a `defer`.
- **X-7** `HTTPClient` uses an ephemeral session, no cookies or cache, follows no redirects, and checks the host
  against the allowlist before any header is sent. It maps every `URLError` to `HTTPFailure.offline`, as today,
  and every other error to `.other`.
- **X-8** `@unchecked Sendable` only with a comment naming the queue or lock that serializes state.

### 8.2 Adapters

| Adapter | Port | From |
| --- | --- | --- |
| `SystemClock` | `Clock` | `BurnieSystem/SystemClock.swift` |
| `TaskSleeper` | `Sleeper` | `BurnieSystem/TaskSleeper.swift` (from the characterization PR) |
| `URLSessionHTTPClient` | `HTTPClient` | `BurnieSystem` |
| `LocalFileReader` | `FileReading` | `BurnieSystem` (+ `exists`, `isExecutable`) |
| `SecurityCLIKeychain` | `SecretReader` | `BurnieSystem` |
| `SQLiteKeyValueReader` | `KeyValueDatabase` | `BurnieSystem` |
| `JSONFileStore` | `SnapshotCache`, `ProviderStorage` | `BurnieSystem` |
| `FoundationProcessRunner` | `ProcessRunner` | generic half of `ClaudeCodeSignInRenewer` |
| `DirectoryWatcher` | `ActivityWatcher` | `ClaudeLogDirectoryWatcher`, made generic |
| `OSDiagnosticsLog` | `DiagnosticsLog` | the `Logger` calls in provider assembly, `URLSessionHTTPClient` and `ClaudeCodeSignInRenewer` |
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
- **C-6** Every component has a `#Preview` and a render smoke test (`T-9`). Previews take their values from
  `PreviewValues` (`#if DEBUG`, in Components): invented descriptors, snapshots and copy, never a real provider's. It is
  the one Components file C-4 and C-5 don't apply to.
- **C-7** Accessibility labels for every icon-only control.

### 9.2 Components

`BurnieDivider`, `BurnieSwitchStyle`, `ChipButton`, `HoverHighlightStyle`, `IconButton`, `IssueRow`, `MeterView`,
`PlanChip`, `Spin`, `SwitchRow`, `UpdateBadge`, `FooterItem`, `MenuBarIcon`, `WeekChartView`, `ProviderRow`,
`SignInRenewalRow`, `PreviewFrame` and `PreviewValues` (both `#if DEBUG`), and `DesignTokens` (today's `Tokens.swift`,
minus provider colors).

---

## 10. App target

### 10.1 Rules (`V-*`)

- **V-1** Views read `AppModel.state` and `AppModel.clock` and call `AppModel.useCases`. Nothing else from Application.
- **V-2** Views contain no business logic: they select, lay out and wire. Branching on a capability or feature with
  `if let` is fine; branching on a provider is not (`G-5`).
- **V-3** The composition root (`App/Composition/`) is the only code that imports `BurnieProviders` and
  `BurnieInfra`. It builds adapters, provider bundles and the app model, in that order. Previews (`App/Previews/`,
  `#if DEBUG`) may import `BurnieProviders` only to read each provider's `descriptor` (P-3), never `bundle`.
- **V-4** Previews build an `AppState` value and `AppModel.preview(_:)`. Every scenario of section 16.7 has a
  preview, except VoiceOver, which is only checked live.
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
| B-8 | A failed limits refresh doesn't flip today's usage from money back to tokens (the unit is the last successful one), not even after a relaunch, where the cached snapshot's unit stands in until limits succeed again. | Domain |
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
| B-17 | An `.activityOnly` snapshot over a cached `.limits` one keeps the cached limits part (plan, meters, unit and on-demand) and its stamp (stale data beats a gap). | Domain |
| B-18 | A total failure over a cached snapshot shows the cache with the issue on top; without a cache, the failure alone. | Domain |
| B-19 | The cache is saved after every successful compose, as shown (after merge, partial issue included); a total failure saves nothing. | Application |

### 11.3 Issues and sign-in

| ID | Behavior | Layer |
| --- | --- | --- |
| B-20 | `rateLimited` and `offline` show no issue row: the header's age already says the data is old. | Interface |
| B-21 | Issue copy per provider: not found, sign-in expired, missing scope (Claude), unexpected ("Couldn't read usage. Burnie may need an update."). | Interface + Providers |
| B-22 | An expired sign-in shows "Refresh sign-in" only when the provider can renew; on failure the row shows the renewal's `failedCopy`. | Components + Application |
| B-23 | A successful renewal triggers a manual refresh of that provider's limits. | Application |
| B-24 | HTTP: no network or timeout → offline; 429 → rate limited with `Retry-After` (seconds or HTTP date); 5xx → offline; other non-2xx → unexpected. | Providers |
| B-25 | Claude: 401 → sign-in expired; 403 mentioning `user:profile` → missing scope; other 403 → sign-in expired; an expired token is detected before any request. | Providers |
| B-26 | Cursor: 3xx, 401, 403 or HTML instead of data → sign-in expired; no database or row → not found; malformed or expired JWT → sign-in expired without network. | Providers |
| B-27 | Claude credentials: Keychain first, then the credentials file. | Providers |
| B-28 | Claude's plan comes from the profile at most once an hour, keeps the last good one, and falls back to the credentials' plan. | Providers |
| B-29 | Providers screen status line: "Off" while disabled; "{displayName} not found"; "Sign-in expired · open {displayName}"; any other state, a specific issue included, shows the provider's healthy line. | Interface + Providers |

### 11.4 Refresh

| ID | Behavior | Layer |
| --- | --- | --- |
| B-30 | Policies: Claude limits 5 min ± 30 s, stale on open 60 s, network; Claude activity 5 min, no jitter, not on open, no network; Cursor limits 10 min ± 30 s, 60 s, network; Cursor activity 30 min, no jitter, 10 min, network. | Providers |
| B-31 | Timer, manual, wake and activity-changed always run; popover-opened runs when older than stale-on-open; network-restored runs when older than the interval. | Domain |
| B-32 | Single flight per task. | Application |
| B-33 | After a 429, nothing is requested from that task before `retryAt`, not even with Refresh; without `Retry-After`: 1, 2, 4… minutes up to 60; any other outcome resets. | Domain + Application |
| B-34 | Offline skips tasks that need the network. Burnie starts online until the system reports otherwise. | Application |
| B-35 | The next timer fires at `retryAt` during backoff, else after interval ± jitter. A timer that fires when its task can't run (offline) isn't re-armed: the job waits for network restored, which runs it if it's older than its interval and otherwise arms its timer, so no job is left without one (decision 47; today it could stall until another trigger). | Application |
| B-36 | The timer releases itself before running, so cancelling it never cancels a request in flight. | Application |
| B-37 | Activating providers starts their tasks without waiting; deactivating cancels their timers; updates are chained in order. | Application |
| B-38 | Wake triggers a refresh 3 s later; network restored triggers one when going offline → online. | Application |
| B-39 | Opening the popover: both open signals arrive together, debounced to one within 1 s; it always lands on the usage screen; its refresh shows the spinner (B-59). | Application + App |

### 11.5 Activity and history

| ID | Behavior | Layer |
| --- | --- | --- |
| B-40 | With the On-demand switch off, sections hide the on-demand meter; the switch only appears when an enabled snapshot has on-demand, judged before hiding, so turning it off keeps the switch. | Domain + Application |
| B-41 | The activity window is today and the 7 days before. | Domain |
| B-42 | History rewrites the window's days on each activity refresh (0 for days the activity doesn't mention), freezes older days, prunes past 35 days. Pruning is per provider: a disabled provider's days stay until it records again. | Domain |
| B-43 | The week chart: 7 days ending today (the latest event's day, so it rolls over with the first event after midnight), zero-filled, one bar per enabled provider per day, one shared peak; empty days draw a 2 pt track mark, non-empty bars are at least 2 pt. | Domain + Components |
| B-44 | Claude log scan is incremental: only new bytes per file; a last line without newline waits for the next scan; truncated files are reread without double counting; duplicates by message key are counted once across files; unreadable lines count as diagnostics and never break the scan; files untouched since before the window are dropped. | Providers |
| B-45 | Claude scans the XDG log root first, then `~/.claude`; no root at all is `notFound`. | Providers |
| B-46 | An unreadable or old log index is discarded and rebuilt; a failed save only means a rescan next launch. | Providers |
| B-47 | Cursor tokens come from the events CSV requested only for the window; spend comes from paged usage events until a short page; a count mismatch, an event without a valid charge, or a failed spend request (a 429 included, which starts no backoff) makes the sum unknown (no partial sums) without failing the activity part, so today's usage reads in tokens. | Providers |
| B-48 | Cursor meters: individual plans show Cursor Models and Other Models as percents (unit tokens); team/enterprise show one Included usage meter in money (unit money); on-demand appears only when enabled, after the other meters, with "Kicks in after included usage runs out" while unused; a summary without usage buckets or billing cycle end is unexpected. | Providers |
| B-49 | Claude meters: prefer `limits[]` (`session`, `weekly_all`), fall back to flat windows; a window without reset shows "No active session"; no windows at all is unexpected. | Providers |

### 11.6 Settings and app features

| ID | Behavior | Layer |
| --- | --- | --- |
| B-50 | First launch: every provider enabled, ring on, week chart on, on-demand shown. | Application |
| B-51 | Turning a provider off keeps its cache and history and stops its watcher and timers; turning it on resumes them. A refresh that finishes after its provider was turned off (or off and on) is dropped. | Application |
| B-52 | One favorite: the heart replaces the previous one or clears it; a disabled provider can't be marked; an unknown stored id reads as no favorite and is left as is. | Domain |
| B-53 | Ring: only with the switch on, an effective favorite and a ready snapshot with meters; it follows the primary meter rounded to whole percents. | Domain |
| B-54 | VoiceOver reads "Burnie usage" or "Burnie usage, {Provider} {n}%". | Interface |
| B-55 | Header: "Updating…" before any data, "Updated just now", "Updated {n} min ago", "Updated {n} h ago"; hidden with every provider off. | Interface + App |
| B-56 | Providers screen header: "{enabled} of {total} tracking". | Interface |
| B-57 | An update shows a dot on the gear and an Update row; scheduled checks never open Sparkle's alert; a skipped version clears the dot on the next check. | Infra + App |
| B-58 | Launch at login is re-read when the providers screen appears; if turning it on needs approval, System Settings opens. | Application + Infra |
| B-59 | The Refresh button spins and is disabled while any refresh request is open (the button's, the popover's or a sign-in renewal's) until every run it started finishes. | Application + App |

### 11.7 Security and privacy

| ID | Behavior | Layer |
| --- | --- | --- |
| B-60 | HTTP only to each provider's allowed hosts, checked before headers are sent; no redirects followed. | Infra |
| B-61 | Burnie never refreshes or rotates Claude's token; renewal runs Claude Code itself. | Providers |
| B-62 | Burnie never writes to `~/.claude`, `~/.config/claude`, the Keychain or `state.vscdb`. | Infra |
| B-63 | The renewal process gets a clean environment, a folder without `.claude/`, no tools, no user settings, no session persistence, and its output is discarded. | Providers + Infra |
| B-64 | Logs carry counts, timings and status codes only; any other interpolation is `.private`. (Today's public method, path and error descriptions go, decision 42.) | Infra |

### 11.8 Limits and fallbacks

| ID | Behavior | Layer |
| --- | --- | --- |
| B-70 | An HTTP request times out after 10 s, which reads as offline (B-24). | Infra |
| B-71 | A sign-in renewal is stopped after 60 s and counts as failed. | Infra + Providers |
| B-72 | The activity watcher coalesces changes over 2 s and watches the directories it was built for that exist when it starts; a directory created later is picked up the next time it starts (the next launch, or turning the provider on again). | Infra + Providers |
| B-73 | Without a usable `Application Support/Burnie/`, the cache and history go to a temporary directory and the app still runs. | Infra + App |
| B-74 | The "Ring in menu bar" switch is disabled without an effective favorite and keeps its stored value; its subtitle says how to mark one, or whose ring it shows. | Interface + App |
| B-75 | The footer has one dashboard link per enabled provider, in registry order, then Quit (⌘Q). | App |

---

## 12. Persistence contract

What's on disk must survive the refactor. Each item has a decoding test against a fixture with the current shape
and invented values (`T-7`).

| Data | Where | Format | Compatibility |
| --- | --- | --- | --- |
| Enabled providers | `UserDefaults` `enabledProviders` | array of provider id strings, sorted | **Must** keep. Absent = every provider in the registry, so a provider added in an update starts enabled. Written only when a provider switch changes (`SettingChange.enabled`), never by another setting's save. Ids not in the registry are ignored on launch and dropped on the next save of this key, as today. |
| Favorite | `UserDefaults` `favoriteProvider` | provider id string | **Must** keep. Unknown id = none, key untouched. |
| Ring shown | `UserDefaults` `showRing` | bool, default true | **Must** keep. |
| Week chart shown | `UserDefaults` `showWeekChart` | bool, default true | **Must** keep. |
| On-demand shown | `UserDefaults` `showOnDemand` | bool, default true | **Must** keep. `UserDefaultsSettingsStore` maps `FeatureToggle.onDemand` to this key explicitly; a new toggle adds its own key here. |
| History | `Application Support/Burnie/history.json` | `{ "<provider id>": { "yyyy-MM-dd": tokens } }` | **Must** keep: it can't be rebuilt (sources forget old days). |
| Snapshots | `Application Support/Burnie/snapshot-<provider id>.json` | `UsageSnapshot` (new shape: `content` as a `SnapshotContent` enum with the stamped `LimitsPart`, unit included, and the partial issue) | **Replaced.** The flat shape (`fetchedAt`, `plan`, `today`, `meters`) is not read back: an old file that doesn't decode reads as no cache (loading), never a crash. Costs one refresh on first launch. |
| Claude log index | `Application Support/Burnie/claude-log-index.json` (Claude's `ProviderStorage` name `log-index`) | `ClaudeLogIndex` | **May** be invalidated (costs one full window rescan); never crash. |

Provider id strings (`claude`, `cursor`), meter id strings (`session`, `weekly`, `cursorModels`, `otherModels`,
`included`, `onDemand`) and specific issue codes (`missingScope`) are frozen: the newtypes encode exactly these raw
values, and `SpecificIssue` encodes as its bare code. Every newtype encodes as its bare
raw value through a single-value container (`ProviderID` as `"claude"`, `Tokens` as `1250000`, never
`{"count": 1250000}`), and `ProviderID` and `LocalDay` are `CodingKeyRepresentable`, so `history.json` stays a JSON
object of objects. Dates encode as seconds since 1970, as `JSONFileStore` does today.

The new snapshot shape is written by hand, not left to synthesized `Codable`: every enum (`SnapshotContent`,
`MeterValue`, `MeterCaption`, `ProviderIssue`, `TodayUsage`, `UsageUnit`) encodes as an object keyed by its case name.
A case without payload holds `{}` (`{"offline": {}}`); a single unlabeled payload is the value itself
(`{"percent": 64}`, `{"tokens": 1250000}`); labeled payloads are an object of their labels (`{"money": {"used": 1200,
"limit": 2000}}`), never `_0`. Every struct encodes with its property names. For example, `.limits` encodes as
`{"limits": {"view": {"value": …, "at": 1760000000}, "today": {"tokens": 1250000}}}`. The refactor PR pins it in its own fixture
(`T-7`), and from then on it is frozen like the rest of this section.

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
| 12 | 2026-10-16 | Use cases are what the UI calls (struct of closures, one per thing the user can do); ports are what providers and infra implement. | Agreed |
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
| 25 | 2026-10-16 | `AppState` is time-independent (refined by decision 29). Time-dependent presentation (stale, pace, "Updated n min ago") is evaluated in views with `now` from `AppModel.clock` under a `TimelineView`, not by a tick event in the reducer. | Agreed |
| 26 | 2026-10-16 | No scheduler actor: job state lives in `RuntimeState`, scheduling decisions are pure functions, timers are effects the interpreter performs with `Sleeper`. The jitter sample travels in the event. | Agreed |
| 27 | 2026-10-16 | The refactor lands in one PR, preceded by two preparatory PRs (guardrails, characterization). No ticket-by-ticket migration: nothing has to compile against half-moved code. | Agreed |
| 28 | 2026-10-16 | Features travel inside the limits view, so merge never splits plan, meters and on-demand. | Agreed |
| 29 | 2026-10-16 | Events carry `now` and `today`; the reducer never reads a clock, and the week chart rolls over with the first event after midnight. Refines decision 25. | Agreed |
| 30 | 2026-10-16 | The reducer marks a run in the step that asks for it, with a never-reused `RunID`; an outcome from a stale run is dropped, so a refresh that finishes after its provider was turned off no longer shows. | Agreed |
| 31 | 2026-10-16 | Refresh requests are tracked until every run they started finishes; the spinner follows them and awaiting use cases resume through `finishRequest`. | Agreed |
| 32 | 2026-10-16 | Ports that need a provider's data reach it as factories in its provider ports. `ProcessRunner`'s allowlist is a parameter; the Keychain adapter runs `security` itself. | Agreed |
| 33 | 2026-10-16 | `HTTPClient` returns an `HTTPResponse` (status, headers, MIME type, body) or throws an `HTTPFailure`; `RingState` carries a whole percent, not a `Fraction`. | Agreed |
| 34 | 2026-10-16 | Settings are saved one key at a time (`SettingChange`), so an absent `enabledProviders` stays absent until a provider switch changes; the reducer drops ids the registry doesn't know. | Agreed |
| 35 | 2026-10-16 | `compose` returns `Result<UsageSnapshot, ProviderIssue>`; the cache is saved only after a compose success, partial issue included; the snapshot wire format is written by hand, dates as seconds since 1970. | Agreed |
| 36 | 2026-10-16 | Every armed timer carries a never-reused `TimerID`, so a `timerFired` from a cancelled or replaced timer is dropped. | Agreed |
| 37 | 2026-10-16 | `DiagnosticsLog` takes a `StaticString` event and numeric `Measure`s only; a provider's log and storage come bound to its id, so there is no `makeLog(category:)`. | Agreed |
| 38 | 2026-10-16 | A GitHub Actions workflow runs `make verify` on every PR, from the guardrails PR on. | Agreed |
| 39 | 2026-10-16 | "Feature" only means a snapshot feature; what the user can do is a use case. | Agreed |
| 40 | 2026-10-16 | Module `AGENTS.md` files point to this spec's sections and list their rule IDs; the rules' text lives only here. | Agreed |
| 41 | 2026-10-16 | Each provider exposes its `descriptor` besides `bundle`, so previews read it without ports; component previews take invented values from a DEBUG `PreviewValues` file, the only one exempt from C-4 and C-5. | Agreed |
| 42 | 2026-10-16 | Adapters built for a provider log only through its `DiagnosticsLog`; the rest use `os.Logger` with every non-number `.private`. The HTTP log keeps status and time and drops today's public method and path. | Agreed |
| 43 | 2026-10-16 | `AppModel.live` loads the persisted state through synchronous ports and reduces `launched` before returning, so the first frame shows the cache; `state` is assigned only when it changes. | Agreed |
| 44 | 2026-10-16 | One event per display switch instead of a generic setting event; `providerToggled` ignores no-op toggles; `RefreshUsage` takes no `force`, since only the button calls it. | Agreed |
| 45 | 2026-10-16 | The renewal-failed copy lives in `SignInRenewal`, so a provider that can't renew has no dead copy; `Link` becomes `DashboardLink` so it doesn't clash with SwiftUI's. | Agreed |
| 46 | 2026-10-16 | `LimitsView` folds into `LimitsPart`, so the cached snapshot keeps its unit and `compose` uses it until limits succeed again (B-8 across launches). | Agreed |
| 47 | 2026-10-16 | After network restored, a job that doesn't run arms its timer: every job has a run or a timer unless it waits for the network. | Agreed |
| 48 | 2026-10-16 | The checks skip comments, see unstaged new files and leave `scripts/` out; `make check` scans the whole tree for sensitive data; G-9 gets a check; C-4 covers every literal measurement and stays dormant until the refactor PR. | Agreed |

---

## 14. Delivery plan

The refactor lands in one PR (decision 27), not in tickets: nothing in between has to compile against half-moved
code, and the old modules (`BurnieCore`, `BurnieSystem`) are deleted in that same PR. Two small PRs come first,
because they are the net that proves the big one changed structure and not behavior.

### 14.1 Before · Guardrails PR

- `scripts/check-architecture.sh` with the rules of section 16.2, printing `SPEC <rule>: <file>:<line>: <message>`.
  Rules for modules that don't exist yet stay dormant until their folder appears (holds a Swift file). Its own test
  (`scripts/check-architecture-test.sh`) runs over two sample trees, today's layout and the target one.
- `scripts/check-sensitive.sh` (section 16.6).
- `make check` (the architecture check's test, then both scripts, the sensitive one with `--all`) and `make verify`
  (`check` + `test` + `build`).
- `.github/workflows/verify.yml`: `make verify` on every PR, on a macOS runner with the Xcode that builds the app
  today (the `xcode-27` image, Xcode 27.1 picked with `DEVELOPER_DIR`), after installing XcodeGen (Homebrew), which
  `make build` runs; no secrets and no signing: Debug already signs ad hoc (decision 38). The checkout action is pinned
  to a commit.
- Root `AGENTS.md`: the commands table gains `make check` and `make verify`, and the workflow asks for `make verify`
  green instead of `make test` and `make build`.
- `BurnieTestSupport` test-support target at `BurnieKit/Tests/BurnieTestSupport`, so everything under `BurnieKit/Tests/`
  is test code: `FixedClock`, port fakes, `Gen` (seeded property-test generators), fixture loading. `Gen` gets its first
  uses in property tests (T-8) for the 4.4 laws that already hold on today's types (`LocalDay`, the meter's fraction
  clamp, `UsageHistory.record`, `RateLimitBackoff`, merge as `keepingMeters(of:)`); the refactor PR retargets them
  (16.5). `ManualSleeper` comes with the `Sleeper` port, the seam the characterization PR adds: before it there is
  nothing for it to fake.
- Nested `CLAUDE.md` files (`@AGENTS.md`) in each module folder, excluded from targets in `Package.swift` and `project.yml`
  (section 17).
- Today's files with more than one top-level type, or one not named like the file, are split or renamed, so G-4 holds
  before the refactor starts: `HoverHighlightStyle.swift`, `UsageStore.swift`, `URLSessionHTTPClient.swift`,
  `UsageStore+Preview.swift`, and in the tests `ClaudeLimitsFetcherTests.swift`, `ClaudeLogActivityTests.swift`,
  `DisplayTextTests.swift`, `MoneyFormatterTests.swift`, `FakeSources.swift` (`FakeLimitsSource`,
  `FakeActivitySource`) and `TestValues.swift` (`FixedClock`). `@unchecked Sendable` gets the comment G-11 asks for
  where it lacks one (`Reports` in `ClaudeLogActivityTests.swift`).
- Every force unwrap the G-9 check flags today gets the comment G-9 asks for, saying why it can't fail: the literal
  URLs in `ClaudeLimitsFetcher`, `ClaudeProfilePlan`, `CursorSummaryFetcher`, `CursorSpendFetcher`,
  `CursorEventsFetcher` and `ProviderID+Display`; the fixed time zones in `LocalDay` (`UTC`) and
  `UsageStore+Preview`; and `LocalDay`'s calendar unwraps (`start(in:)`, `components`, `utcDate`, `advanced(by:)`),
  which can't fail because every `LocalDay` holds a validated `yyyy-MM-dd`. The `try!` in `CursorSpendFetcher`
  already has its comment.
- Rules on today's layout, where `BurnieCore` stands for Domain and `BurnieSystem` for Infra:

  | Rule | In the guardrails PR |
  | --- | --- |
  | G-4, G-7, G-8, G-9, G-11 | active everywhere |
  | G-6 | active; `BurnieSystem` counts as Infra |
  | G-3 | active as `BurnieCore` imports only `Foundation` |
  | D-3 | active on `BurnieCore` |
  | G-5, D-2, D-6, I-2, P-1, A-1, A-5, C-4, C-5, V-3 | dormant: today's code breaks them on purpose (`Tokens.accent` switches on the provider, `BurnieCore` has actors and `async`, the views hold literal copy and about 50 literal measurements, the scheduler calls `Task.sleep`), and the refactor PR wakes them |

- **Done when:** `make verify` green on today's code with the active rules above, locally and in CI.

### 14.2 Before · Characterization PR

- Persistence fixtures and decoding tests for every row of section 12 (`T-7`).
- Tests for behaviors in section 11 that have none today, written against today's code (notably the store and
  scheduler: B-11, B-19, B-32…B-40, B-50, B-51, B-59). Where today's code can't be tested without a seam, add the smallest seam.
  The store, the scheduler and the settings live in the app target, so their tests go in an Xcode unit-test target,
  `BurnieAppTests` (`AppTests/`, not hosted by the app), which `make test` runs after `swift test`. The seams are the
  `Sleeper` and `SystemEvents` ports in `BurnieCore/Ports`, `popoverOpened()` returning the refresh it starts, and
  `RefreshScheduler.timerFired(for:)` made internal so a test can fire a timer while offline.
- B-8 across launches, B-35's timer after network restored, B-43's rollover and B-51's dropped refresh change on
  purpose (decisions 29, 30, 46, 47): their tests pin today's part here, and the refactor PR adds the new part.
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
  and `RefreshJob` disappear. No provider type is public except its entry point, with only `descriptor` and `bundle` (P-3).
- **Infra** (`BurnieInfra`): the adapters of section 8.2, including those moved from `App/Store`; the FSEvents watcher
  and the process runner made generic; no adapter mentions a provider.
- **Application** (`BurnieApplication`): `RuntimeState` with the registry, jobs, runs and requests, `Event`, `Effect`,
  the reducer, the interpreter with its timers and continuations, `Scheduling`, `AppState.derive`, `AppModel`, use
  cases. Every *Application* behavior in section 11 has a test that names its ID, with `FixedClock`, `ManualSleeper`
  and a fixed jitter sample, no real waiting.
- **Components** (`BurnieComponents`): the components of section 9.2, `DesignTokens` with every measurement the views
  and components use today (C-4), provider colors from descriptors; every component has a preview from
  `PreviewValues` and a render smoke test.
- **App**: views on `AppModel`; `App/Composition/` builds everything; previews from `AppState` values; `UsageStore`,
  `RefreshScheduler`, `PreviewScenario`'s store and `Setting` are deleted.
- **Cleanup**: `BurnieCore` and `BurnieSystem` deleted; module `AGENTS.md` files point to this spec (decision 40); the root
  `AGENTS.md` layers table, its `BurnieCore/Ports` reference and its module list rewritten to point to section 3;
  README's build section updated; final /tidy; the spec's status becomes "implemented".
- **Done when:** `make verify` green locally and in CI with no dormant rule left; every characterization test passes, moved to its module
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
| `Domain/Favorite.swift`, `RingState.swift` | → Domain | ring reads `meters.primary` as a whole percent |
| `Domain/Meter.swift`, `Meter+Pace.swift`, `MeterCaption.swift`, `MeterValue.swift` | → Domain | `Fraction`, `Cents` |
| `Domain/MeterID.swift` | → Domain | newtype; the cases move to each provider |
| `Domain/ProviderID.swift` | → Domain | newtype; `claude`/`cursor` constants move to Providers |
| `Domain/ProviderIssue.swift` | → Domain | `missingScope` → Claude `.specific` |
| `Domain/ProviderState.swift`, `TodayUsage.swift`, `UsageUnit.swift`, `UsageHistory.swift` | → Domain | |
| `Domain/UsageSnapshot*.swift` | → Domain | `content: SnapshotContent` replaces `fetchedAt`/`plan`/`today`/`meters` (kept as computed); `merge`, `failing`, `hiding`; `OnDemand` → `SnapshotFeatures` inside the stamped `LimitsPart` |
| `Domain/UsageSource.swift` | deleted | replaced by `PartKind` |
| `Ports/*` | → Interface `Ports/` | `SnapshotStore` splits into `SnapshotCache` and `ProviderStorage`; `SignInRenewer` → `SignInRenewal` capability over `ProcessRunner`; `UsageProvider` deleted (replaced by `ProviderBundle`) |
| `Providers/CompositeUsageProvider.swift` | deleted | logic → Domain `compose` + Application |
| `Refresh/RateLimitBackoff.swift`, `RefreshPolicy.swift`, `RefreshTrigger.swift` | → Domain | `RefreshPolicy.standard(for:)` table → each provider's tasks |
| `Refresh/RefreshJob.swift` | → Application `JobKey.swift` (internal) | keyed by provider + task name |
| `Format/*Formatter.swift`, `RingState+Label.swift` | → Interface `Presentation/` | |
| `Format/ProviderID+Display.swift`, `ProviderID+Status.swift`, `ProviderIssue+Message.swift`, `ProviderIssue+Renewal.swift`, `MeterID+Label.swift` | → descriptors in Providers + `IssueMessage`/`StatusLine` in Interface | switches become data |
| `HTTP/*`, `Parsing/ISO8601DateParser.swift`, `Cursor/CSVParser.swift`, `Cursor/Date+UnixMilliseconds.swift` | → Providers `Shared/` | `HTTPRequest` → Interface (port value), with the new `HTTPResponse` and `HTTPFailure` |
| `Claude/*` | → Providers `Claude/` | `ClaudeLimitsFetcher` and `ClaudeLogActivity` become task bodies; `ClaudePaths` stays provider data |
| `Cursor/*` | → Providers `Cursor/` | `CursorSummaryFetcher` and `CursorActivity` become task bodies |
| `AGENTS.md` | → split into module `AGENTS.md` files | |

### 15.2 `BurnieKit/Sources/BurnieSystem`

| Current | Destination | Notes |
| --- | --- | --- |
| `SystemClock.swift`, `TaskSleeper.swift`, `URLSessionHTTPClient.swift`, `LocalFileReader.swift`, `SecurityCLIKeychain.swift`, `SQLiteKeyValueReader.swift`, `JSONFileStore.swift` | → Infra | |
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
| `Store/AppUpdater.swift` | → Infra `SparkleUpdater` | see open question 1 |
| `Views/` components (section 9.2) | → Components | |
| `Views/` views (section 10.2) | stay | read `AppModel` |
| `Views/Tokens.swift` | → Components `DesignTokens.swift` | provider colors → descriptors |
| `Assets.xcassets` `claude`, `cursor` colorsets | → descriptor `ColorPair` values | other colorsets move with `DesignTokens` |
| `Assets.xcassets` `FlameGlyph` imageset | → Components resources | `MenuBarIcon` loads it with `bundle: .module` (open question 4) |

### 15.4 Tests

| Current | Destination |
| --- | --- |
| `BurnieCoreTests/Domain`, `Refresh` | → `BurnieDomainTests` |
| `BurnieCoreTests/Format`, `ProviderIDTests.swift` | → `BurnieInterfaceTests` / `BurnieProvidersTests` (descriptor copy) |
| `BurnieCoreTests/Claude`, `Cursor`, `Fixtures` | → `BurnieProvidersTests` |
| `BurnieCoreTests/Providers` | → `BurnieDomainTests` (compose) + `BurnieApplicationTests` |
| `BurnieCoreTests/Support` | → `BurnieTestSupport` |
| `BurnieSystemTests` | → `BurnieInfraTests` |
| `AppTests/` (Xcode target `BurnieAppTests`, from the characterization PR) | `UsageStoreTests*`, `RefreshSchedulerTests` → `BurnieApplicationTests`, retargeted to the reducer and `AppModel` (16.5); `SettingTests` → `BurnieInfraTests` (`UserDefaultsSettingsStore`, keys of section 12). Then the target, its scheme, the `BurnieTestSupport` library product and `make test`'s `xcodebuild` line are deleted. |
| new | `BurnieApplicationTests`, `BurnieComponentsTests` |

---

## 16. Verification and quality control

### 16.1 Gates

Every PR runs these, in this order, and they must all pass. CI runs `make verify` on every PR (decision 38); the
author runs the rest and says so in the PR body.

| Gate | Command | Catches |
| --- | --- | --- |
| Architecture | `make check` → `scripts/check-architecture.sh` | layer, purity and naming rules (16.2) |
| Sensitive data | `make check` → `scripts/check-sensitive.sh` | secrets, real paths, emails (16.6) |
| Tests | `make test` | behavior, laws, persistence, copy |
| Build | `make build` | the app target, previews, strict concurrency |
| Performance | `make perf` (PRs that touch scanning, parsing or history) | the 200 MB log scan stays within budget: < 3 s cold, < 50 ms incremental |
| Tidy | /tidy skill | readability, names, nesting |
| Review | checklist (16.8) | what no tool can check |

`make verify` runs architecture, sensitive data, tests and build in one command.

### 16.2 Architecture check

`scripts/check-architecture.sh` greps the Swift files under `App/`, `AppTests/` and `BurnieKit/` that git tracks or
would track (`git ls-files --cached --others --exclude-standard`, so a new file counts before it's staged, and `.build/`
and generated code never do) and fails with the rule ID, file and line. `scripts/` holds standalone tools outside the
layers and isn't checked. Every pattern except G-8's skips comment lines (`//`, `///`), so a doc comment that names a
forbidden call doesn't fail; G-8 reads them, because that's where its markers live.
Rules:

| Rule | Check |
| --- | --- |
| G-3 | Every `import` in a module is in its allowed list (section 3.2). |
| G-4 | A file declares one top-level type, named like the file (a regex over `^(@\w+ )*((public\|internal\|private\|fileprivate) )?(final )?(struct\|enum\|class\|actor\|protocol) `, so private helpers and `final class`es count). |
| G-5 | No `case .claude`, `case .cursor`, `== .claude`, `== .cursor`, `!= .claude`, `!= .cursor` (as whole words: `.claudeNotFound` doesn't match), and no `"claude"` or `"cursor"` string literal outside `BurnieProviders` (persistence fixtures and tests of section 12 allowlisted by path). |
| G-6 | No `Date()`, `Date.now`, `.now` after `(`, `:` or `,` (an implicit member), `Date(timeIntervalSinceNow`, `.timeIntervalSinceNow`, `ContinuousClock.now`, `SuspendingClock.now`, `TimeZone.current`, `Locale.current`, `Calendar.current` outside Infra (its test targets included) and `App/Composition`, except `TimelineView(.periodic(from: .now` and, in `IconButton.swift` only, `Spin(startingAt: .now)`, `stop(at: .now)` and `.timeIntervalSinceNow`. |
| G-7 | No `print(`, `NSLog(`, `debugPrint(` outside the performance test. |
| G-8 | No `TODO`, `FIXME`, `XXX` as whole words, comments included (`ssXXXXX` in a date format isn't one). |
| G-9 | No `try!`, and no `!` right after `)` (`URL(string: "…")!`), outside test targets unless the line above is a comment. Other force unwraps are left to review. |
| G-11 | No `@unchecked Sendable` outside Infra and test targets; where allowed, the line above has a comment. |
| D-2 | No `class `, `actor `, `async`, `Task`, `static var` in `BurnieDomain`. |
| D-3 | No `FileManager`, `URLSession`, `Process`, `UserDefaults`, `Bundle`, `ProcessInfo`, `NotificationCenter` in Domain, Interface, Providers, Application. |
| D-6 | No string literal with letters in Domain except `rawValue`s, coding keys, `Codable` error descriptions, format strings made only of specifiers (`"%04d-%02d-%02d"`) and fixed identifiers (`TimeZone(identifier: "UTC")`), allowlisted by pattern; only the allowed literal is exempt, never the rest of its line. |
| I-2 | No `class `, `actor `, `static var`, and no `var` at file scope in `BurnieInterface`. |
| P-1 | No `os.Logger`, `Logger(` in Providers. |
| A-1 | No `public` type in Application other than `AppModel` and `AppEnvironment`, and no `public` member outside them. |
| A-5 | No `Task.sleep`, `asyncAfter`, `Timer.` in Domain, Interface, Providers or Application; waits go through `Sleeper`. |
| C-4 | No `Color(red:`, `Color(hex`, `#colorLiteral`, and no numeric literal other than `0` as the argument of `.frame(`, `.padding(`, `spacing:`, `cornerRadius:`, `lineWidth:`, `.opacity(`, `.font(.system(size:` in Components and views, outside `DesignTokens.swift` and `PreviewValues.swift`. |
| C-5 | No string literal with a letter as user-visible text in Components or views, outside `PreviewValues.swift`: `Text("`, `Label("`, `Button("`, `Toggle("`, `.accessibilityLabel("`, and the `title:`, `subtitle:`, `label:`, `accessibilityLabel:` arguments. SF Symbol names (`systemName:`) and shortcut keys are allowed. Copy comes from `Copy` or parameters. |
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
| Components | render smoke | each component renders without crashing (`ImageRenderer`), at a non-zero size, with values from `Gen` and the edge states (loading, failed, stale, no meters, no today's usage) |
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
- **T-9** Components render tests live in `BurnieComponentsTests` and run under `make test`. They build their values
  with `BurnieTestSupport` and never depend on `App/Previews`, which test targets can't reach.
- **T-10** A test target `@testable import`s only the module it tests (section 3.2); everything else it reaches
  through that module's API or `BurnieTestSupport`.

### 16.4 Property tests

`BurnieTestSupport/Gen` is a small seeded generator (SplitMix64) with combinators: `int(in:)`, `double` (including
NaN, ±∞, negatives, > 1), `date(around:)`, `localDay(around:)`, `meter`, `meterSet`, `snapshot`, `latest`,
`issue`, `providerID(from:)`. Each law in 4.4 is one parameterized test over 200 seeds. No third-party library.

### 16.5 Characterization and equivalence

Before code moves (the characterization PR), today's behavior is pinned by tests against today's code. In the refactor PR, those tests move with
the code and keep passing; a test may be renamed or retargeted, never weakened. When a function is replaced
(`CompositeUsageProvider` → `compose`), the old and new are both run over the full input table in the PR that
replaces it, and the PR shows that the outputs match. Since the old module is deleted in the same PR, that comparison
lives in an intermediate commit of the PR, and the final commit keeps only the new tests. The squash merge drops that
commit from `main`, so the PR body carries the evidence itself: the commit's hash (it stays reachable on GitHub
through the PR) and the summary of its test output, which the squash commit message keeps.

### 16.6 Sensitive data check

`scripts/check-sensitive.sh` scans the staged diff, or with `--all` every tracked and untracked file that isn't ignored
(what `make check` runs, so CI, where nothing is staged, checks the whole tree), and fails on:

- absolute home paths (`/Users/<name>/`, `/home/<name>/`), also JSON-escaped (`\/Users\/<name>`) and as Claude Code
  names project folders (`-Users-<name>-…`); the placeholder names of invented test data (`dev`, `tester`, `user`…)
  are listed in the script;
- email addresses other than GitHub noreply addresses (and reserved example domains, `example.com`, `.test`…, which
  can't be real mailboxes);
- token-like strings: `sk-ant-` followed by a real token's length (a fixture's short placeholder passes), `Bearer `
  followed by a long token, JWT-shaped strings (`eyJ…\.…\.…`) outside the fixture allowlist (fixtures with invented
  JWTs are listed by path in the script);
- private key headers (`-----BEGIN … PRIVATE KEY-----`), `.p8`, `.p12` files;
- certificate hashes (40-hex strings next to `codesign` or `identity`).

A symlink is scanned as the path it points to, which is what git commits. It never prints a matched value, only the
file, line and rule. Reading `git diff --cached` by eye before every commit stays mandatory (root `AGENTS.md`).

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

- Scope matches its PR in section 14 while the refactor lasts, and its ticket after it; nothing extra.
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
2. **Nested instructions.** Each module folder has a short `AGENTS.md` (the module's purpose, the rule IDs that apply
   with a one-line summary each, and a link to its section here) and a `CLAUDE.md` containing `@AGENTS.md`, so agents
   that load nested `CLAUDE.md` files are sent to the module's rules as soon as they read a file there (added in the
   guardrails PR; both files excluded from build targets). The rules' text lives only in this file, so the two can't
   drift (decision 40).
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
4. **Components module and assets.** Moving the non-provider colorsets and the `FlameGlyph` imageset into
   `BurnieComponents` resources means `Color(_:bundle: .module)` and `Image(_:bundle: .module)`, and the glyph must
   still render as a template in the menu bar. Fine on macOS 14; confirmed in the refactor PR.
5. **Render tests under `swift test`.** `T-9` assumes `ImageRenderer` works in a SwiftPM test run without a window
   server session. If it doesn't, the render smoke tests move to an Xcode test target that `make verify` runs.
   A cheap spike in the guardrails PR is welcome.
6. **Test support before the refactor.** `BurnieTestSupport` lands in the guardrails PR against today's `BurnieCore`
   ports and is rewritten against `BurnieInterface` in the refactor PR. Fixtures stay in each test target's
   resources; the loader takes the bundle as a parameter.
