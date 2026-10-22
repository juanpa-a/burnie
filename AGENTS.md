# Priority #1: a clean, organized implementation

In Burnie, keeping the code very clean and organized is the most important thing in the project.
It beats speed, extra features, and "it already works".

- Run the /tidy skill on every ticket before calling it done and before opening the PR.
- Respect the layers and the ports of `BurnieInterface` (`SPEC.md` section 3). If something doesn't fit them cleanly, stop and escalate; don't work around it.
- Clear names in the domain language (Meter, Snapshot, Provider), small functions, one type per file.
- No dead code, no stray TODOs, no duplication between providers.
- If you have to choose between finishing today and leaving it clean, leave it clean.

# The architecture: read SPEC.md first

Burnie follows the layered, functional architecture in [`SPEC.md`](SPEC.md): its glossary, modules, rules, behavior
catalog, persistence contract and verification gates.

- Before any work that touches layers, names, ports, providers, state or tests, read `SPEC.md`. It wins over the module
  `AGENTS.md` files; it never relaxes the rules in this file.
- Rules have IDs: `G` global, `D` domain, `I` interface, `P` providers, `A` application, `X` infra, `C` components,
  `V` app views, `T` tests, `B` behaviors to keep. Cite them in reviews, commits and PR bodies.
- Name things from the glossary (`SPEC.md` section 2). A new concept is a spec change in the same PR.

# Never commit sensitive information

The repo is public. Nothing sensitive goes into it: not in code, fixtures, docs, commit messages, PR text, or file names.

- Secrets: tokens, cookies, passwords, API keys, private keys (Sparkle EdDSA, `.p8`, `.p12`), and notarization credentials.
- Identifiers: certificate hashes, emails (commits use the GitHub noreply address), account or user ids, and device names.
- Personal data: real home paths (`/Users/<name>`), real usage numbers, and real account dates.
- Values that must reach the build (team ID, signing identity) come in as `make` arguments or from the local Keychain, never written to a tracked file.
- Before every commit, read `git diff --cached` looking for any of the above. If something sensitive was already committed, stop and tell the user: deleting it in a new commit isn't enough.

# Burnie

Menu bar app for macOS 14+ that shows Claude Code and Cursor usage.

## Layers

One Swift package module per layer, inside `BurnieKit`, plus the app target. Dependencies go one way; `SPEC.md`
section 3.2 lists what each may import, and `make check` enforces it.

| Module | What lives there |
| --- | --- |
| `BurnieDomain` | The internal language as types: values and total functions, no I/O and no time source |
| `BurnieInterface` | Ports, the provider contract, use cases, the app state, and every user-visible text |
| `BurnieProviders` | Claude Code and Cursor, each turning its sources into parts behind one entry point |
| `BurnieApplication` | The runtime: a pure reducer, the interpreter that performs its effects, and `AppModel` |
| `BurnieInfra` | Dumb macOS adapters that implement the ports |
| `BurnieComponents` | SwiftUI pieces and the design tokens |
| `App` | Views on `AppModel`, the composition root (`App/Composition`) and the previews |

Each module has its own `AGENTS.md`, listing the rule IDs that apply there. Read it before touching that module.

## Commands

| Command | What it does |
| --- | --- |
| `make gen` | Generates `Burnie.xcodeproj` with XcodeGen. The project is generated: never edit it, change `project.yml`. |
| `make check` | The architecture check (`SPEC.md` section 16.2) and the sensitive-data check over every file. |
| `make test` | `swift test` for the `BurnieKit` package. |
| `make perf` | Release-mode performance test of the log scan (200 MB). |
| `make build` | Builds the app in Debug. |
| `make verify` | `check`, `test` and `build`: what CI runs on every pull request. |
| `make run` | Builds and opens the app. |
| `make install` | Builds a Release copy signed ad hoc, installs it in `/Applications` (or `APPS_DIR`), and opens it. |
| `make dmg` | Builds the same ad hoc copy, packs it into `build/Burnie.dmg` with the install window, and opens it. |
| `make release TEAM_ID=…` | Archive signed with a Developer ID, notarized `build/release/Burnie.dmg`, and Sparkle's `appcast.xml`. |

## Workflow

- One ticket = one branch and one PR. It isn't closed without `make verify` green and a /tidy pass.
- Tests use Swift Testing (`import Testing`), one test target per module. Fixtures live in each target's `Fixtures`
  folder (`BurnieProvidersTests`, and the persistence ones in `BurnieDomainTests`) and keep the real shape with invented
  values: no real tokens, emails, ids, paths, account dates, or usage data.
- Burnie is read-only over `~/.claude`, `~/.config/claude`, the Keychain, and `state.vscdb`. It only writes to `~/Library/Application Support/Burnie/`, plus what Sparkle needs to install an update the user asked for.
