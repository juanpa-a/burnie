<p align="center"><img src="docs/icon.png" width="128" alt="Burnie's icon: a smiling flame on black"></p>

# Burnie

A small macOS menu bar app that shows how much of your Claude Code and Cursor plans you've used.

Click the flame icon in the menu bar to see:

- **Claude Code:** your plan, the 5-hour session and weekly limits with their reset times, and today's tokens.
- **Cursor:** your plan, the Cursor Models and Other Models pools (or included usage on team plans), on-demand spend when it's on, and today's tokens.
- **Activity chart:** daily tokens for each provider over the last 7 days, with each one's total for its current cycle: Cursor's billing cycle, Claude's weekly limit. Hover a day to see its tokens.

Every bar except on-demand has a small tick where you'd be at an even pace: halfway through a 5-hour session, it sits in the middle. If you're using it faster than that, the part of the bar past the tick turns red.

Burnie reuses the sign-ins Claude Code and Cursor already have on your Mac. It never asks for a password and never writes to their files. You can turn each provider on or off from the gear button, and mark one with ♥ so a ring around the flame shows its usage without opening anything.

## Requirements

- macOS 14 Sonoma or later.
- Claude Code and/or Cursor installed and signed in on the same Mac.

## Install

1. Download `Burnie.dmg` from the [latest release](https://github.com/juanpa-a/burnie/releases/latest).
2. Open it and drag **Burnie** onto **Applications**.
3. Open Burnie from Applications. The flame icon shows up in the menu bar; Burnie has no Dock icon.

To start Burnie when you log in, click the flame, then the gear button, and turn on **Launch at login**.

### Update

Burnie checks for a new version once a day. When there is one, a blue dot shows on the gear button: click the gear, then **Update**, and Burnie installs it and relaunches.

### Uninstall

1. Open Burnie, turn off **Launch at login** if you turned it on, and choose **Quit**.
2. Delete `/Applications/Burnie.app`.
3. Optionally, delete its cache and settings:

   ```sh
   rm -rf ~/Library/Application\ Support/Burnie
   defaults delete dev.juanpa.burnie
   ```

## Privacy

- **What it reads.**
  - Claude Code, only when `~/.claude` or `~/.config/claude` exists: its sign-in, from the Keychain item `Claude Code-credentials` (read with `/usr/bin/security` before each limits refresh) or `~/.claude/.credentials.json`, and the token counts in its local logs in `~/.claude/projects` and `~/.config/claude/projects`. Burnie never reads the messages in those logs.
  - Cursor: its sign-in token from `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`, read-only and never copied, sent only to `cursor.com` as the dashboard's session cookie. When Cursor encrypts that token, Burnie decrypts it in memory with the password in Cursor's Keychain item `Cursor Safe Storage` (read by Burnie itself once per launch and kept only in memory; macOS asks you the first time, and **Always Allow** lets only Burnie read it). Only your own usage is shown: a team-wide budget shows as **Team pool** or **Team on-demand**, never as yours and never in the menu bar ring.
- **Who it talks to.** `api.anthropic.com` and `cursor.com` for usage, only ever reading (every request is a `GET`), and `github.com` once a day to check for a new Burnie. Updates come only from a signed feed, are verified before they're opened, and never install without you. No analytics or telemetry.
- **What it writes.** Only its cache and history in `~/Library/Application Support/Burnie/`. Tokens, cookies and Keychain passwords never touch the disk or the logs.
- **What it runs.** Only when you press **Refresh sign-in** under an expired Claude sign-in: your installed `claude`, asking Haiku for a one-word reply. Claude Code then renews and saves its own sign-in; Burnie never handles the refresh token.

Burnie relies on undocumented Claude and Cursor endpoints. If one changes, Burnie shows "Couldn't read usage. Burnie may need an update." until it's updated.

### Checking a copy

The release DMG is signed with a Developer ID and notarized by Apple. To check an installed copy, run:

```sh
spctl --assess --verbose /Applications/Burnie.app
codesign --display --verbose=2 /Applications/Burnie.app
```

## Development

Burnie is built in layers, one Swift package module each, with a pure core and every effect behind a port; [`SPEC.md`](SPEC.md) describes the architecture, its rules and the behavior it keeps.

| Command | What it does |
| --- | --- |
| `make run` | Builds a Debug copy and opens it. |
| `make test` | Runs the `BurnieKit` tests. |
| `make verify` | The architecture and sensitive-data checks, the tests and the Debug build: what CI runs on every pull request. |
| `make perf` | Release-mode performance test of the log scan. |
| `make install` | Builds a Release copy and installs it, as below. |
| `make release TEAM_ID=…` | Builds a signed, notarized `Burnie.dmg` and the `appcast.xml` for updates. |

### Building from source

Needs Xcode 26 or later, opened once so it finishes setting up (the Command Line Tools alone aren't enough), and [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`.

```sh
git clone https://github.com/juanpa-a/burnie.git
cd burnie
make install
```

`make install` builds a release copy, signs it for this Mac only (no Apple developer account needed), copies it to `/Applications/Burnie.app`, and opens it. To install it somewhere else, pass a folder: `make install APPS_DIR=~/Applications`. To see the install window that `Burnie.dmg` opens to, run `make dmg`.

That copy is for working on Burnie: it has no Developer ID, no notarization and no hardened runtime, so a managed Mac can't approve it. To share Burnie, share the release DMG.

### Releasing

Once per Mac: install a Developer ID Application certificate (Xcode → Settings → Accounts → Manage Certificates), store the notarization credentials with `xcrun notarytool store-credentials burnie-notary`, and keep Sparkle's private EdDSA key in the Keychain (`generate_keys` creates it; `generate_keys -x` exports a backup and `-f` imports it on another Mac).

1. In `project.yml`, raise `MARKETING_VERSION` (0.x while Burnie is an MVP) and add one to `CURRENT_PROJECT_VERSION`. Merge that change.
2. Run `make release TEAM_ID=<your team>`. It signs the DMG and the `appcast.xml` with the EdDSA key: installed copies only accept a signed appcast.
3. Run the `gh release create` command it prints. Installed copies see the update on their next daily check.

Sparkle's tools live in `build/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin` after any `make build`.

The rules for contributing (human or agent) live in [`AGENTS.md`](AGENTS.md).

## Credits

App icon by [Albert Hassey](https://github.com/ahasseyp).
