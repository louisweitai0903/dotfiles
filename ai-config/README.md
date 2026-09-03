# ai-config

Portable AI agent instructions. One canonical file, symlinked into every AI coding
tool so they all follow the same rules — edit it once, every agent picks it up.

## How it works

`AGENTS.md` is the single source of truth. Every tool-specific config file each
agent looks for is a **symlink** pointing at it:

| Tool          | Global config it reads      | Linked to  |
|---------------|------------------------------|------------|
| Claude Code   | `~/.claude/CLAUDE.md`        | `AGENTS.md` |
| Codex CLI     | `~/.codex/AGENTS.md`         | `AGENTS.md` |
| Gemini CLI    | `~/.gemini/GEMINI.md`        | `AGENTS.md` |
| GitHub Copilot| `<project>/.github/copilot-instructions.md` (per-project only, no global slot) | `AGENTS.md`, via `link-copilot.sh` |

Because these are symlinks, not copies, editing `AGENTS.md` (directly, or by
asking any agent to update it) instantly changes behavior for every tool on
this machine — no syncing step needed locally.

## Setting up a new machine

```bash
git clone git@github.com:louisweitai0903/dotfiles.git ~/dotfiles
cd ~/dotfiles/ai-config
./install.sh
```

`install.sh` is idempotent and backs up (`.bak.<timestamp>`) anything that
isn't already the expected symlink before replacing it.

## Linking a project for Copilot

Copilot has no global instructions file — it only reads
`.github/copilot-instructions.md` per repo:

```bash
~/dotfiles/ai-config/link-copilot.sh /path/to/project
```

## Growing this over time

When you (or an agent) learn a new durable preference or convention:

1. Edit `AGENTS.md` in this repo (or ask the current agent to do it).
2. Commit and push:
   ```bash
   cd ~/dotfiles
   git add ai-config/AGENTS.md
   git commit -m "ai-config: <what changed>"
   git push
   ```
3. On any other machine, `git pull` picks it up immediately (the symlinks
   already point into this repo).

Keep entries general and durable — things true across most/all projects, not
project-specific detail (that belongs in the project's own CLAUDE.md/README).
