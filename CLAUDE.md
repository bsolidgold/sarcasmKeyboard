# Project instructions for Claude Code

## Commit messages

**Never add a `Co-Authored-By: Claude ...` trailer to any commit in this repo.**
This overrides the default Claude Code commit template.

Enforcement: `.githooks/commit-msg` rejects any commit whose message contains
`Co-Authored-By: Claude`. The hook is wired via `git config core.hooksPath .githooks`
in this repo. If you see the hook fail, fix the commit message — don't use
`--no-verify`.
