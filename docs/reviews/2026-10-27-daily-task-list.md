# Review: Per-project daily task list, with local-only handoffs and task files

- **Date:** 2026-10-27
- **Branch:** main (HEAD 9610ce8)
- **Verdict:** PASS

## Summary
This adds a global agent rule (`daily-tasks.md`) for a per-project daily task list at `docs/tasks/YYYY-MM-DD.md`. The top-level session reads today's file at session start and treats its open items as today's objectives, unless the user asks for something else. Off-list work gets added as a new item. If no file exists, the session creates one and asks what else is planned for the day. When an item is done (after its commit), it is ticked and gets a `Changes:` line with the key files and commit SHAs, and the daily `## Summary` is rewritten. Task files and handoff files (`/HANDOFF.md`, `/docs/handoffs/`) are made local-only: they are listed in `$(git rev-parse --git-common-dir)/info/exclude` and must never be committed. `/handoff` now ensures those excludes, links to today's task file and summarises it, and says "Never commit" where it used to say "committed with the next piece of work". `AGENTS.md` is regenerated from the docs.

## Files changed
- [ai-config/docs/daily-tasks.md:1](../../ai-config/docs/daily-tasks.md#L1) — New rule: file location, session-start behaviour, file format, how to mark items done, and rules (re-read before edit, never delete, no secrets or PII, top-level session only).
- [ai-config/docs/documentation-standards.md:93](../../ai-config/docs/documentation-standards.md#L93) — New "Local-only files" section: which paths, the `info/exclude` mechanism, never stage or commit them, and tell the user if a path is already tracked.
- [ai-config/skills/handoff/SKILL.md:16](../../ai-config/skills/handoff/SKILL.md#L16) — Step 1 ensures the excludes. Step 3 gathers today's task file ([L33](../../ai-config/skills/handoff/SKILL.md#L33)). The template adds a "Today's tasks" section ([L49](../../ai-config/skills/handoff/SKILL.md#L49)). Step 7 becomes "Never commit" ([L112](../../ai-config/skills/handoff/SKILL.md#L112)).
- [ai-config/build.sh:15](../../ai-config/build.sh#L15) — Adds `daily-tasks.md` to ORDER, after `before-starting.md`.
- [ai-config/AGENTS.md:59](../../ai-config/AGENTS.md#L59) — Regenerated output with the new "Daily Task List" section and "Local-only files" ([L368](../../ai-config/AGENTS.md#L368)).
- [ai-config/README.md:44](../../ai-config/README.md#L44) — The `/handoff` row notes that handoffs are local-only. A new docs-table row for `daily-tasks.md` ([L99](../../ai-config/README.md#L99)).

## What was fixed
Nothing; this is a feature. No bugs were found or fixed along the way. It deliberately reverses the earlier rule (commit 6bd4371) that handoff files get committed with the next piece of work.

## Coverage
Most of this change is instructions an LLM agent follows, so it can't be tested automatically. The rows marked "manual" were checked by reading the text. The git-exclude mechanism was proven in a throwaway repo.

| Scenario / flow | Handled by | Proven by |
|---|---|---|
| Session start, today's file exists: name the open items and follow the user's request even if it is off-list; add off-list work as a new item | [daily-tasks.md:12](../../ai-config/docs/daily-tasks.md#L12) | manual (instruction text) |
| Session start, no file: don't block; create the file with the first concrete task; ask what else is planned today | [daily-tasks.md:12](../../ai-config/docs/daily-tasks.md#L12) | manual |
| Unfinished items from an earlier day: offer to carry them over, don't copy them silently | [daily-tasks.md:12](../../ai-config/docs/daily-tasks.md#L12) | manual |
| Per project: file sits under the git toplevel (or cwd outside git); skipped in the home directory | [daily-tasks.md:1](../../ai-config/docs/daily-tasks.md#L1) | manual |
| Mark done with changes and a daily summary | [daily-tasks.md:49](../../ai-config/docs/daily-tasks.md#L49) | manual |
| Untracked task and handoff files are invisible to `git status` and `git add -A`, and an explicit `git add` is refused | [documentation-standards.md:93](../../ai-config/docs/documentation-standards.md#L93) | Throwaway repo in the scratchpad: with the three patterns in `info/exclude`, `docs/tasks/*` and `docs/handoffs/*` did not appear in `git status`; `git add docs/tasks/2026-10-27.md` returned "paths are ignored" |
| `--git-common-dir` resolves correctly from a subdirectory | [documentation-standards.md:93](../../ai-config/docs/documentation-standards.md#L93) | Throwaway repo: printed `../../.git` (cwd-relative) from `docs/tasks/`; also confirmed in this repo |
| `/handoff` links to today's task file and summarises it, and never commits | [SKILL.md:49](../../ai-config/skills/handoff/SKILL.md#L49), [SKILL.md:112](../../ai-config/skills/handoff/SKILL.md#L112) | manual; relative link `../tasks/` from `docs/handoffs/` checked |
| Subagents (for example this reviewer) don't create task files | [daily-tasks.md:9](../../ai-config/docs/daily-tasks.md#L9) | manual |
| `AGENTS.md` matches the build output | [build.sh:15](../../ai-config/build.sh#L15) | Rebuilt the concatenation from staged blobs into the scratchpad and diffed it against the staged `AGENTS.md`: identical |

## Edge cases
| Edge case | How it's handled | Tested? |
|---|---|---|
| Repo already tracks `HANDOFF.md` or handoffs (under the old rule) | Rule says tell the user and don't untrack it. `info/exclude` has no effect on tracked files | Yes. A tracked `HANDOFF.md` still showed as modified and was staged by `git add -A` despite the exclude. The protection is only the prose rule (see Findings 1) |
| Not a git repo | Root = cwd; no exclude needed | manual |
| Home directory / no project | Skip unless the user asks | manual |
| Git worktree | `--git-common-dir` points at the shared `info/exclude` | not tested; correct according to git docs |
| `.git/info/` missing (empty `--template`) | Not handled; an append to `info/exclude` fails with "no such file or directory" | Yes, reproduced (Finding 2) |
| Session crosses local midnight | Not specified which date's file gets the "done" mark | No (Finding 3) |
| Two sessions editing the same day's file | Re-read before every edit and only touch your own items; no locking | manual; acceptable for personal notes |
| Dropped items | `- [-]` with a reason; never delete | manual |
| Secrets or PII in task notes | Explicitly forbidden | manual |

## Not tested
- **Agent compliance with the session-start and mark-done instructions** — These are natural-language rules with no test harness. That's acceptable for a dotfiles config. Confirm by starting a fresh Claude Code session in a project with and without a `docs/tasks/<today>.md`.
- **Worktree behaviour of `--git-common-dir`** — Low risk; it is documented git behaviour.

## Production rollout & downtime
Not live. These are personal dotfiles. Because `~/.claude/CLAUDE.md` is a symlink to `ai-config/AGENTS.md`, the new rules take effect in new sessions as soon as the working tree changes, before any commit. Rollback is reverting the commit.

## Checklist
### Done
- [x] User enters today's work list; it is documented per date (`docs/tasks/YYYY-MM-DD.md`)
- [x] Daily summary section, rewritten when items finish
- [x] Done items are marked with their changes (files, commit SHAs)
- [x] No separate skill; rule lives in global instructions and runs at session start
- [x] Session follows the user's request when it differs from the list ("unless specified to work on something else")
- [x] Per project
- [x] In-project but untracked (option b), using `info/exclude`
- [x] `/handoff` links to and summarises today's task file
- [x] Handoffs never committed (skill step 7, Local-only files, README)
- [x] `build.sh` ORDER updated and `AGENTS.md` regenerated in sync
- [x] README updated (skills table and docs table)
- [x] Existing hook tests still pass
### Not done
- [ ] STATUS.md / PROGRESS.md / HANDOFF.md for the dotfiles repo — OK for this commit because they are pre-existing gaps, not introduced here.
- [ ] Automated tests for the rules — OK for this commit because they are prose instructions; validation is manual.

## Findings
1. **[non-blocking] Already-tracked handoffs stay committable** — In any project that followed the previous rule (commit 6bd4371: handoffs committed with the next piece of work), `HANDOFF.md` and `docs/handoffs/*` are already tracked. `info/exclude` does nothing for tracked paths. The next `/handoff` edits `HANDOFF.md`, and a later `git commit -a` or `git add -A` puts it in a commit, which I reproduced in a throwaway repo. The only guard is the "tell the user / never stage" prose. Two options:
   - **Option A:** Have `/handoff` and the session-start rule run `git ls-files HANDOFF.md docs/handoffs docs/tasks` and warn explicitly when anything is listed.
   - **Option B:** Offer the user `git rm --cached` with their approval. This is the actual fix, but it is a tracked-file removal, so it needs consent.
2. **[non-blocking] `info/exclude` append fails when `.git/info/` doesn't exist** — With repos initialised from an empty or custom `--template`, `>> "$(git rev-parse --git-common-dir)/info/exclude"` fails with "no such file or directory" (reproduced). The agent would probably recover, but the instruction doesn't cover it. Two options:
   - **Option A:** Say `mkdir -p "$(git rev-parse --git-common-dir)/info"` first.
   - **Option B:** Use `git rev-parse --git-path info/exclude`, which resolves correctly for worktrees and from subdirectories, plus `mkdir -p` of its dirname.
3. **[non-blocking] Midnight rollover is unspecified** — A session starts on 2026-10-27, and the item's commit lands at 00:30 on 2026-10-28. "Mark it after the work's commit" doesn't say which file to update. The agent may create a new file for the 28th with a stray done item, leaving the 27th's item open. A suggested fix is one line: "mark it in the file where the item lives."
4. **[non-blocking] "Required structure" still lists `HANDOFF.md`** — [documentation-standards.md:10](../../ai-config/docs/documentation-standards.md#L10) lists it as a required project file, but it is now local-only, so a fresh clone never has it. An agent could create or commit a placeholder to "satisfy" the structure. A suggested fix is to annotate that tree entry with "(local-only, see below)".
5. **[non-blocking] `- [-]` isn't GitHub-flavoured Markdown task syntax** — Dropped items render as a plain bullet reading "[-]" rather than as a checkbox. This is cosmetic only, since the files are local notes.

## Tests & checks run
- `bash ai-config/hooks/test-commit-review-gate.sh` — All tests passed.
- `bash -n ai-config/build.sh` — syntax OK.
- Rebuilt `AGENTS.md` from staged doc blobs into the scratchpad and diffed it against the staged `AGENTS.md` — identical. I did not run `build.sh` itself because it writes in place.
- `git diff --stat` (unstaged) — empty; the staged change doesn't depend on unstaged work.
- Throwaway-repo experiment in the scratchpad: untracked files under excluded paths were hidden and refused, a tracked `HANDOFF.md` was still staged by `add -A`, `--git-common-dir` from a subdirectory gave `../../.git`, and the append failed when `info/` was missing. A first attempt that included a `git commit` was blocked by the commit-review gate hook, so I redid it without committing.
- No linter is configured for Markdown in this repo; `shellcheck` and `markdownlint` are not installed.

## Risks & follow-ups
- Projects with already-committed handoffs need a one-off user decision: keep tracking them, or `git rm --cached` with approval (Finding 1).
- The session-start rule adds a file read and possibly a question to every top-level session in a project. Watch whether this gets noisy in practice.
- Consider Findings 2 to 4 as small wording follow-ups.
