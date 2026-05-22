# Project instructions for Claude Code

## Quick reference

- **Platform:** iOS 17.0+, Swift 5.9, SwiftUI
- **Project generator:** XcodeGen (`xcodegen generate` regenerates `SarcasmKeyboard.xcodeproj`)
- **Engine tests:** `swift test` (131 tests, no simulator needed)
- **Default simulator:** iPhone 16

## Build commands

| Task | Command |
|---|---|
| Regenerate Xcode project | `xcodegen generate` |
| Build for simulator | `/build` (uses XcodeBuildMCP) |
| Run on simulator | `/run` (builds, installs, launches, screenshots) |
| Engine unit tests | `/test` or `swift test` |
| Screenshot current state | `/screenshot` |

**XcodeBuildMCP is configured** in `.mcp.json` — use `mcp__xcodebuildmcp__*` tools for all Xcode operations. Never use raw `xcodebuild` shell commands when XcodeBuildMCP tools are available.

## Signing (required for device/TestFlight builds)

`DEVELOPMENT_TEAM` is intentionally left blank in `project.yml`. To sign locally, create `.claude/settings.local.json` (already gitignored):

```json
{
  "env": {
    "DEVELOPMENT_TEAM": "YOUR_TEAM_ID"
  }
}
```

Then set it in `project.yml` before archiving. The user must do this — it cannot be automated.

## Architecture notes

- `SarcasmKit` (`Sources/SarcasmKit/`) — pure Swift, no UIKit/SwiftUI. Portable to Android later.
- `SarcasmKeyboard/` — iOS companion app (SwiftUI)
- `SarcasmKeyboardExtension/` — keyboard extension (UIKit host, SwiftUI keyboard view)
- App Group: `group.com.sarcasmkeyboard.app` — shared UserDefaults between app and extension
- StoreKit product: `com.sarcasmkeyboard.app.pro.unlock` — one-time $2.99 Pro unlock

## Commit messages

**Never add a `Co-Authored-By: Claude ...` trailer to any commit in this repo.**
This overrides the default Claude Code commit template.

Enforcement: `.githooks/commit-msg` rejects any commit whose message contains
`Co-Authored-By: Claude`. The hook is wired via `git config core.hooksPath .githooks`
in this repo. If you see the hook fail, fix the commit message — don't use
`--no-verify`.
