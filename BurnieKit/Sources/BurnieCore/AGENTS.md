# BurnieCore

No I/O, no `Date()`, everything testable with fixtures.

- Only `import Foundation`. No AppKit, SwiftUI, `FileManager.default`, `URLSession`, `Process`, or SQLite.
- Time comes in through the `Clock` port; never `Date()` or `TimeZone.current`. The locale comes in as a parameter.
- Disk, network, and Keychain only through the ports in `Ports/`. What orchestrates them (fetchers, scanner) lives here and is tested with fakes.
- Mappers are pure functions from DTO to domain types. The UI never sees a DTO.
- Folders: `Domain/` types the UI sees, `Ports/` protocols, `Claude/` and `Cursor/` everything specific to each provider, `Providers/` how a provider's two sources combine, `Refresh/` cadences and backoff, `Format/` visible text, `Parsing/` and `HTTP/` pieces the providers share.
- A total failure of a source throws `ProviderIssue`; a partial one travels in `UsageSnapshot.issue`.
