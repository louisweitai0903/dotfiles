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
| `/commit-review [slug]` | skill (`skills/commit-review`) | Reviews the whole feature branch against its base in a fresh subagent, writes `docs/reviews/YYYY-MM-DD-<slug>.md` (coverage, edge cases, untested areas, done/not-done checklist, findings, PASS/BLOCK), commits it on the branch, then pushes and opens the draft PR. Only for branches that change code — docs-only branches skip it. |
| `commit-reviewer` | subagent (`agents/commit-reviewer.md`) | The read-only, fresh-context reviewer `/commit-review` delegates to. |
| `commit-review-gate.sh` | PreToolUse hook (`hooks/`) | Denies `git commit` on `main`/`master`/`dev`/`staging`, and `gh pr create` unless the branch has a committed `docs/reviews/*.md` file (at the repo root or in a subproject). Logs decisions to `~/.claude/logs/commit-review-gate.log`. |

Gate rules:
- Commits on `main`, `master`, `dev` or `staging` are denied (except the
  initial commit of a brand-new repo). Commits on any other branch, or on a
  detached HEAD, are allowed with no review: the review happens once per
  branch, before the PR.
- `git switch`/`git checkout` in the same command as a commit is denied,
  because the hook runs before the switch and can't see which branch the
  commit lands on.
- `gh pr create` is denied unless `git diff <base>...HEAD` contains a
  committed (added or modified, not deleted) review file. The base is
  `--base`/`-B`, else `origin/HEAD`, else `origin/main`, `origin/master`,
  `main`, `master`. A `--base` that's quoted, a variable, or doesn't exist
  is denied.
- Docs-only branches need no review: if every changed path (including
  deletions and both sides of a rename) is a `.md`, `.mdx`, `.markdown`,
  `.rst`, `.txt` or `.adoc` file, or an extensionless LICENSE/CHANGELOG/
  CHANGES/AUTHORS/CONTRIBUTORS/NOTICE/COPYING file, the PR is allowed
  (`changes.py` or `Notice.tsx` still need review; `.txt` includes
  `requirements.txt` and `CMakeLists.txt`, by choice).
- A commit and `gh pr create` in the same command are denied: commit, push
  and open the PR as separate commands.
- Quoted text and heredoc bodies (commit messages, PR bodies, `echo`/`grep`
  arguments, `"$(cat <<'EOF' …)"`) are ignored when matching, so mentioning
  `git commit` or `gh pr create` in a message or search doesn't trip the gate.
- The target repo is the session's working directory, then any
  `cd <path>` earlier in the command, then the commit's own `git -C <path>`.
  Paths must be literal: a variable (`$REPO`), a quoted `cd` path, or more
  than one quoted `git -C` in the same command can't be resolved
  unambiguously, so the command is denied.
- Fails closed: once a command is recognized as a commit or PR, any internal
  error in the hook blocks it (exit 2) rather than letting it through.

Tests: `./hooks/test-commit-review-gate.sh` (throwaway repos, no side
effects). Run it after any change to the hook.

Gate limits: it only covers commands Claude runs (your own terminal is
untouched), and it checks that a review file is on the branch, not that the
review is current. Push, merge and PR-approval rules (`--force`, protected
refspecs, `gh pr merge`/`ready`/`review --approve`) are instructions only,
not enforced by the hook. Not detected: commands wrapped in a quoted string
(`bash -c "git commit …"`, `sh -c '…'`), git/gh aliases (`git ci`), and
`gh` creating a PR any other way. A `cd` inside a subshell
(`(cd x && make); git commit`) is still applied. Unquoted text such as
`echo git commit` still counts as a commit. With `--git-dir`/`--work-tree`
the repo is still resolved from the working directory. Without `jq` the
hook allows everything.

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
| `scope-control.md` | Keeping changes to what was actually asked |
| `implementation-standards.md` | Code quality expectations |
| `frontend-references.md` | Research design references and wait for a choice before building UI |
| `database-migrations.md` | Migration safety rules |
| `dependencies.md` | Rules for adding/upgrading packages |
| `documentation-standards.md` | README/STATUS/PROGRESS/HANDOFF/docs conventions |
| `feature-review.md` | Fresh-session review of the whole branch + review file required before the draft PR |
| `commit-messages.md` | Git workflow: feature branches, Conventional Commits, push and draft PR rules |
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
2. Rebuild and ship it through a feature branch and draft PR (see
   `docs/commit-messages.md`; the gate denies commits on `main`):
   ```bash
   cd ~/dotfiles
   git switch -c docs/<what-changed>
   cd ai-config && ./build.sh && cd ..
   git add ai-config/
   git commit -m "docs(ai-config): <what changed>"
   # code/config/script changes: in Claude Code run /commit-review, which
   # commits docs/reviews/YYYY-MM-DD-<slug>.md on the branch
   git push -u origin HEAD
   gh pr create --draft --base main
   ```
3. Once the PR is merged, `git pull` on any machine picks it up immediately
   (the symlinks already point into this repo's `AGENTS.md`).

Keep entries general and durable — things true across most/all projects, not
project-specific detail (that belongs in the project's own CLAUDE.md/README).
Never hand-edit `AGENTS.md` directly — it's generated and gets overwritten
the next time `build.sh` runs.
