# BurnieSystem

Implements the `BurnieCore` ports; never logs secrets.

- Each adapter implements one port and nothing else. Business logic goes in `BurnieCore`.
- `Providers/` assembles each provider from core pieces and concrete adapters (real paths, user, version).
- Logs use `os.Logger(subsystem: "dev.juanpa.burnie", category: <provider>)`: HTTP codes, timings, and counts. Never tokens, cookies, `userId`, or response bodies. Dynamic interpolations use `privacy: .private` except numbers.
- Read-only over other apps' files. Temporary SQLite copies go to a dedicated directory with 0700 permissions and are deleted in a `defer`.
- `Process` only runs `/usr/bin/security`, and Claude Code's own `claude` when the user presses Refresh sign-in. Always an absolute path and fixed arguments; `claude` gets a clean environment and its output is discarded.
