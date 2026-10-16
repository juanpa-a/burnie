# Priority #1: a clean, organized implementation

In Burnie, keeping the code very clean and organized is the most important thing in the project.
It beats speed, extra features, and "it already works".

- Run the /tidy skill on every ticket before calling it done and before opening the PR.
- Respect the layers below and the ports in `BurnieCore/Ports`. If something doesn't fit them cleanly, stop and escalate; don't work around it.
- Clear names in the domain language (Meter, Snapshot, Provider), small functions, one type per file.
- No dead code, no stray TODOs, no duplication between providers.
- If you have to choose between finishing today and leaving it clean, leave it clean.

# Burnie

Menu bar app for macOS 14+ that shows Claude Code and Cursor usage.

## Layers

Dependencies go one way only: `App` → `BurnieSystem` → `BurnieCore`.

| Module | What lives there | Rule |
| --- | --- | --- |
| `BurnieKit/Sources/BurnieCore` | Domain, ports, DTOs, parsers, mappers, formatters, and the logic that orchestrates ports | Only `import Foundation`; no I/O, no `Date()`, no `TimeZone.current` |
| `BurnieKit/Sources/BurnieSystem` | macOS adapters that implement the ports, and the assembly of each provider | Never logs or stores secrets |
| `App` | SwiftUI views, `UsageStore`, `RefreshScheduler`, and wiring | No business logic |

Each module has its own `AGENTS.md`. Read it before touching that module.

## Commands

| Command | What it does |
| --- | --- |
| `make gen` | Generates `Burnie.xcodeproj` with XcodeGen. The project is generated: never edit it, change `project.yml`. |
| `make test` | `swift test` for the `BurnieKit` package. |
| `make perf` | Release-mode performance test of the log scan (200 MB). |
| `make build` | Builds the app in Debug. |
| `make run` | Builds and opens the app. |
| `make install` | Builds a Release copy signed ad hoc, installs it in `/Applications` (or `APPS_DIR`), and opens it. |
| `make release TEAM_ID=…` | Archive signed with a Developer ID, notarized `build/release/Burnie.dmg`, and Sparkle's `appcast.xml`. |

## Workflow

- One ticket = one branch and one PR. It isn't closed without `make test` and `make build` green and a /tidy pass.
- Tests use Swift Testing (`import Testing`). Fixtures live in `BurnieKit/Tests/BurnieCoreTests/Fixtures` and keep the real shape with invented values: no real tokens, emails, ids, paths, account dates, or usage data.
- Burnie is read-only over `~/.claude`, `~/.config/claude`, the Keychain, and `state.vscdb`. It only writes to `~/Library/Application Support/Burnie/`, plus what Sparkle needs to install an update the user asked for.
