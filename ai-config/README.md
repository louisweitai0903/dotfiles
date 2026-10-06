# ai-config

Portable AI agent instructions. One generated file, symlinked into every AI
coding tool so they all follow the same rules — edit a doc once, every agent
picks it up.

## How it works

`docs/*.md` are the source of truth — one focused file per topic (commit
messages, code review, execution planning, security, etc). `build.sh`
concatenates them, in order, into `AGENTS.md`. That generated `AGENTS.md` is
the single file every tool-specific config is a **symlink** to:

| Tool          | Global config it reads      | Linked to  |
|---------------|------------------------------|------------|
| Claude Code   | `~/.claude/CLAUDE.md`        | `AGENTS.md` |
| GitHub Copilot| `<project>/.github/copilot-instructions.md` (per-project only, no global slot) | `AGENTS.md`, via `link-copilot.sh` |

Not currently wired up: Codex CLI, Gemini CLI (not in use). `AGENTS.md` is
still a generic filename by convention — re-adding either tool later is just
adding a `link` line back to `install.sh`.

Because these are symlinks, not copies, rebuilding `AGENTS.md` instantly
changes behavior for every tool on this machine — no per-tool syncing step
needed locally.

## What's in docs/

| File | Covers |
|------|--------|
| `role.md` | The senior-engineer mindset every response should have |
| `safety.md` | Destructive commands that always need explicit approval |
| `before-starting.md` | What to understand before writing any code |
| `execution-plan.md` | When and how to write a plan before implementing |
| `scope-control.md` | Keeping changes to what was actually asked |
| `implementation-standards.md` | Code quality expectations |
| `frontend-references.md` | Research design references and wait for a choice before building UI |
| `database-migrations.md` | Migration safety rules |
| `dependencies.md` | Rules for adding/upgrading packages |
| `documentation-standards.md` | README/STATUS/PROGRESS/HANDOFF/docs conventions |
| `feature-review.md` | Fresh-session review + review file required before each commit |
| `commit-messages.md` | Commit message format and git workflow |
| `code-review.md` | Review checklist, for others' code and self-review |
| `security-review.md` | Security checklist (injection, authz, secrets, etc) |
| `debugging.md` | Systematic bug reproduction and root-causing |
| `linting.md` | Linting/type-checking expectations per language |
| `testing.md` | What must be verified before calling something done |
| `validation.md` | Post-implementation validation checklist |
| `communication.md` | How to report finished work |
| `decision-making.md` | How to choose between multiple valid approaches |
| `definition-of-done.md` | The final checklist for "is this task actually done" |

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

1. Edit the relevant file in `docs/` (or add a new one, and add it to the
   `ORDER` array in `build.sh`).
2. Rebuild and push:
   ```bash
   cd ~/dotfiles/ai-config
   ./build.sh
   cd ~/dotfiles
   git add ai-config/
   git commit -m "ai-config: <what changed>"
   git push
   ```
3. On any other machine, `git pull` picks it up immediately (the symlinks
   already point into this repo's `AGENTS.md`).

Keep entries general and durable — things true across most/all projects, not
project-specific detail (that belongs in the project's own CLAUDE.md/README).
Never hand-edit `AGENTS.md` directly — it's generated and gets overwritten
the next time `build.sh` runs.
