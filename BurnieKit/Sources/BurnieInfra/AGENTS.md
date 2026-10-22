# BurnieInfra

Dumb adapters: each implements one port of `BurnieInterface` with a macOS technology, and nothing else. An adapter
never knows a provider: what a provider needs (hosts, directories, executables) arrives as parameters.

The rules' text lives only in [`SPEC.md`](../../../SPEC.md): `G-*` in
[3.3](../../../SPEC.md#33-rules-for-every-module-g-), `X-*` in [8.1](../../../SPEC.md#81-rules-x-), the adapters in
[8.2](../../../SPEC.md#82-adapters).

- **X-1** One adapter per port per file, named after its technology.
- **X-2** No business rules; a provider detail is a parameter.
- **X-3** Never logs or stores secrets: an adapter a provider's factory builds logs only through its `DiagnosticsLog`;
  any other uses `os.Logger` with every non-number `.private`.
- **X-4** Read-only over other apps' files and the Keychain; writes only to `Application Support/Burnie/` (0700 folder,
  0600 files, atomic), `UserDefaults`, and what Sparkle needs for an update the user asked for.
- **X-5** The process runner only runs its allowlist, with fixed arguments, a minimal environment, a folder without
  `.claude/`, no input or output, and a timeout.
- **X-6** SQLite opens read-only with a timeout; when busy, it reads a private copy deleted in a `defer`.
- **X-7** HTTP: ephemeral session, no cookies or cache, no redirects, hosts checked before any header is sent.
- **X-8** `@unchecked Sendable` only with a comment naming the queue or lock that serializes state.
