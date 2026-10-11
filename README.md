# Burnie

A small macOS menu bar app that shows how much of your Claude Code and Cursor plans you've used.

Click the flame icon in the menu bar to see:

- **Claude Code:** your plan, the 5-hour session and weekly limits with their reset times, and today's tokens.
- **Cursor:** your plan, the Cursor Models and Other Models pools (or included usage on team plans), on-demand spend when it's on, and today's tokens.
- **Last 7 days:** daily tokens for each provider.

Burnie reuses the sign-ins Claude Code and Cursor already have on your Mac. It never asks for a password and never writes to their files. You can turn each provider on or off from the gear button, and mark one with ♥ so a ring around the flame shows its usage without opening anything.

## Requirements

- macOS 14 Sonoma or later.
- Xcode 26 or later, opened once so it finishes setting up. The Command Line Tools alone aren't enough.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`.
- Claude Code and/or Cursor installed and signed in on the same Mac.

## Install

```sh
git clone https://github.com/juanpa-a/burnie.git
cd burnie
make install
```

`make install` builds a release copy, signs it for this Mac only (no Apple developer account needed), copies it to `/Applications/Burnie.app`, and opens it. The flame icon shows up in the menu bar; Burnie has no Dock icon.

To install it somewhere else, pass a folder: `make install APPS_DIR=~/Applications`.

To start Burnie when you log in, open it, click the gear button, and turn on **Launch at login**.

### Update

```sh
cd burnie
git pull
make install
```

### Uninstall

1. Open Burnie, turn off **Launch at login** if you turned it on, and choose **Quit**.
2. Delete `/Applications/Burnie.app`.
3. Optionally, delete its cache and settings:

   ```sh
   rm -rf ~/Library/Application\ Support/Burnie
   defaults delete dev.juanpa.burnie
   ```

## Install with an agent

Paste this prompt into Claude Code, or any coding agent that can run commands on your Mac:

```text
Install the Burnie menu bar app from https://github.com/juanpa-a/burnie on this Mac.

1. Check the requirements and stop to tell me what's missing:
   - macOS 14 or later (`sw_vers -productVersion`).
   - Xcode 26 or later (`xcodebuild -version`). If only the Command Line Tools are installed, or Xcode asks to finish setting up, tell me what to do instead of trying to fix it.
   - XcodeGen (`command -v xcodegen`). If it's missing and Homebrew is installed, run `brew install xcodegen`. If Homebrew isn't installed, ask me before installing it.
2. Clone the repo into ~/Developer/burnie, or run `git pull` there if it already exists.
3. From the repo, run `make install`. If /Applications isn't writable, run `make install APPS_DIR=~/Applications` instead.
4. Confirm Burnie is running (`pgrep -x Burnie`) and tell me to click the flame icon in the menu bar.

Rules: don't use sudo. Don't read, print, or change anything in ~/.claude, ~/.config/claude, the Keychain, or Cursor's files; Burnie reads what it needs by itself. If a step fails, show me the error and stop.
```

## Privacy

- **What it reads.** Claude Code's sign-in from the Keychain (`Claude Code-credentials`) or `~/.claude/.credentials.json`, and its local logs in `~/.claude/projects` and `~/.config/claude/projects`. Cursor's sign-in from `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`.
- **Who it talks to.** Only `api.anthropic.com` and `cursor.com`. No analytics, telemetry, or update checks.
- **What it writes.** Only its cache and history in `~/Library/Application Support/Burnie/`. Tokens and cookies never touch the disk or the logs.

Burnie relies on undocumented Claude and Cursor endpoints. If one changes, Burnie shows "Couldn't read usage. Burnie may need an update." until it's updated.

## Development

| Command | What it does |
| --- | --- |
| `make run` | Builds a Debug copy and opens it. |
| `make test` | Runs the `BurnieKit` tests. |
| `make perf` | Release-mode performance test of the log scan. |
| `make install` | Builds a Release copy and installs it, as above. |

The rules for contributing (human or agent) live in [`AGENTS.md`](AGENTS.md).
