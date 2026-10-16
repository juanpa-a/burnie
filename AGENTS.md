# Priority #1: a clean, organized implementation

In Burnie, keeping the code very clean and organized is the most important thing in the project.
It beats speed, extra features, and "it already works".

- Run the /tidy skill on every ticket before calling it done and before opening the PR.
- Respect the layers below and the ports in `BurnieCore/Ports`. If something doesn't fit them cleanly, stop and escalate; don't work around it.
- Clear names in the domain language (Meter, Snapshot, Provider), small functions, one type per file.
- No dead code, no stray TODOs, no duplication between providers.
- If you have to choose between finishing today and leaving it clean, leave it clean.

# Never commit sensitive information

The repo is public. Nothing sensitive goes into it: not in code, fixtures, docs, commit messages, PR text, or file names.

- Secrets: tokens, cookies, passwords, API keys, private keys (Sparkle EdDSA, `.p8`, `.p12`), and notarization credentials.
- Identifiers: Apple team ID, certificate hashes, emails (commits use the GitHub noreply address), account or user ids, and device names.
- Personal data: real home paths (`/Users/<name>`), real usage numbers, and real account dates.
- Values that must reach the build (team ID, signing identity) come in as `make` arguments or from the local Keychain, never written to a tracked file.
- Before every commit, read `git diff --cached` looking for any of the above. If something sensitive was already committed, stop and tell the user: deleting it in a new commit isn't enough.

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
