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

## Folder layout

| Path | What lives there | Installed to |
|------|------------------|--------------|
| `docs/*.md` | Source of truth for the rules, one topic per file | Concatenated into `AGENTS.md` by `build.sh` |
| `AGENTS.md` | Generated — never hand-edit | `~/.claude/CLAUDE.md` (symlink) |
| `skills/<name>/SKILL.md` | Claude Code skills (slash commands) | `~/.claude/skills/<name>` (symlink to the folder) |
| `agents/<name>.md` | Claude Code custom subagents | `~/.claude/agents/<name>.md` (symlink) |
| `hooks/*.sh` | Claude Code hook scripts, plus `test-*.sh` tests for them | `~/.claude/hooks/` (symlink), registered in `~/.claude/settings.json`; tests aren't installed |

Skills, agents and hooks implement rules from `docs/` — keep them in sync:
if a rule changes, update the skill/agent that carries it out.

## Skills, agents and hooks

| Name | Kind | What it does |
|------|------|--------------|
| `/handoff [title]` | skill (`skills/handoff`) | Writes `docs/handoffs/handoff-<title>-YYYY-MM-DD-HHMM.md` for the current session, updates the `HANDOFF.md` index, and ends with a one-line resume prompt to paste into a new session. Handoff files are local-only (added to `.git/info/exclude`, never committed). Manual only. |
| `/commit-review [slug]` | skill (`skills/commit-review`) | Reviews the staged changes in a fresh subagent, writes `docs/reviews/YYYY-MM-DD-<slug>.md` (coverage, edge cases, untested areas, done/not-done checklist, findings, PASS/BLOCK) and stages it. Only for commits that include code — docs-only commits skip it. |
| `commit-reviewer` | subagent (`agents/commit-reviewer.md`) | The read-only, fresh-context reviewer `/commit-review` delegates to. |
| `commit-review-gate.sh` | PreToolUse hook (`hooks/`) | Denies `git commit` commands Claude runs (see gate limits below) unless a `docs/reviews/*.md` file (at the repo root or in a subproject) is staged. Logs decisions to `~/.claude/logs/commit-review-gate.log`. |

Gate rules:
- Docs-only commits need no review: if every changed path (including
  deletions and both sides of a rename) is a `.md`, `.mdx`, `.markdown`,
  `.rst`, `.txt` or `.adoc` file, or an extensionless LICENSE/CHANGELOG/
  CHANGES/AUTHORS/CONTRIBUTORS/NOTICE/COPYING file, the commit is allowed
  (`changes.py` or `Notice.tsx` still need review; `.txt` includes
  `requirements.txt` and `CMakeLists.txt`, by choice). Any other file
  in the commit means a review is required.
- Stage files in a separate command before committing. `git add x && git commit`
  is denied, because the hook runs before the `git add` and can't see what
  will be committed.
- Commits that name paths (`git commit <paths>`, `--`, `-o`/`--only`, `-i`,
  `--pathspec-from-file`) are denied: they commit only those paths and can
  silently leave the staged review file out.
- With nothing staged, only a message-only `--amend` or `--allow-empty` is
  allowed. An `--amend` that adds files is allowed if HEAD already contains
  a review file.
- Quoted text and heredoc bodies (commit messages, `echo`/`grep` arguments,
  `"$(cat <<'EOF' …)"`) are ignored when matching, so mentioning
  `git commit`, `-a` or `git -C` in a message or search doesn't trip the gate.
- The target repo is the session's working directory, then any
  `cd <path>` earlier in the command, then the commit's own `git -C <path>`.
  Paths must be literal: a variable (`$REPO`), a quoted `cd` path, or more
  than one quoted `git -C` in the same command can't be resolved
  unambiguously, so the commit is denied.
- Fails closed: once a command is recognized as a commit, any internal error
  in the hook blocks it (exit 2) rather than letting it through.

Tests: `./hooks/test-commit-review-gate.sh` (throwaway repo, no side effects).
Run it after any change to the hook.

Gate limits: it only covers commits Claude runs (your own terminal commits
are untouched), and it checks that a review file is staged, not that the
review is current. Not detected: a commit wrapped in a quoted string
(`bash -c "git commit …"`, `sh -c '…'`) and git aliases (`git ci`). A `cd`
inside a subshell (`(cd x && make); git commit`) is still applied. And
unquoted text such as `echo git commit` still counts as a commit. With
`--git-dir`/`--work-tree` the repo is still resolved from the working
directory. Without `jq` the hook allows everything.

To add a skill: create `skills/<name>/SKILL.md`, re-run `./install.sh`, and
restart Claude Code.

## What's in docs/

| File | Covers |
|------|--------|
| `role.md` | The senior-engineer mindset every response should have |
| `safety.md` | Destructive commands that always need explicit approval |
| `before-starting.md` | What to understand before writing any code |
| `daily-tasks.md` | Read/create the project's `docs/tasks/YYYY-MM-DD.md` at session start (local-only, like handoffs); mark items done with their changes and keep a daily summary; `/handoff` links to it |
| `execution-plan.md` | When and how to write a plan before implementing |
| `goal-driven-execution.md` | Turn each task into a checkable goal, loop until it passes, add a regression test for every error caught, report only evidence |
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

`install.sh` is idempotent and backs up anything that isn't already the
expected symlink to `~/.claude/backups/<name>.bak.<timestamp>` before
replacing it (outside `skills/` and `agents/`, so backups never load as
duplicate skills). It links
`AGENTS.md`, every skill, agent and hook, and adds the commit-review hook to
`~/.claude/settings.json` once (backing that file up first). Requires `jq`
for the hook.

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
2. Rebuild, review, commit and push (in Claude Code, stage first, then run
   `/commit-review` — the gate denies `git add … && git commit` in one
   command and commits without a staged review file):
   ```bash
   cd ~/dotfiles/ai-config
   ./build.sh
   cd ~/dotfiles
   git add ai-config/
   # in Claude Code: /commit-review  → stages docs/reviews/YYYY-MM-DD-<slug>.md
   git commit -m "docs[ai-config] -- <what changed>"
   git push
   ```
3. On any other machine, `git pull` picks it up immediately (the symlinks
   already point into this repo's `AGENTS.md`).

Keep entries general and durable — things true across most/all projects, not
project-specific detail (that belongs in the project's own CLAUDE.md/README).
Never hand-edit `AGENTS.md` directly — it's generated and gets overwritten
the next time `build.sh` runs.
