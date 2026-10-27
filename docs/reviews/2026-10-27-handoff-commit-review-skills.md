# Review: /handoff and /commit-review skills, commit-reviewer subagent, commit-review gate hook

- **Date:** 2026-10-27
- **Branch:** main (HEAD 4c022d9)
- **Verdict:** BLOCK

## Summary
This change adds two Claude Code skills. `/handoff` writes one handoff file per session to `docs/handoffs/handoff-<title>-YYYY-MM-DD-HHMM.md`, keeps `HANDOFF.md` as an index (Latest plus History), and ends with a one-line resume prompt. `/commit-review` passes the staged diff to a new read-only `commit-reviewer` subagent with fresh context, writes `docs/reviews/YYYY-MM-DD-<slug>.md`, and stages it. A new PreToolUse Bash hook (`commit-review-gate.sh`) denies any `git commit` that Claude runs unless a `docs/reviews/*.md` file goes into that commit. The hook has its own test script. `install.sh` now symlinks skills, agents and hooks into `~/.claude` and registers the hook in `~/.claude/settings.json`. The rule docs and the generated `AGENTS.md` describe the new workflow.

## Files changed
- [ai-config/hooks/commit-review-gate.sh:1](../../ai-config/hooks/commit-review-gate.sh#L1): new PreToolUse gate. It strips quoted text and heredocs from the command, detects `git commit`, resolves the repo, parses commit arguments, checks the staged files for a review file, and fails closed once it has recognized a commit.
- [ai-config/hooks/test-commit-review-gate.sh:1](../../ai-config/hooks/test-commit-review-gate.sh#L1): new test suite (about 50 scenarios) run against a throwaway repo, including an injected internal error.
- [ai-config/install.sh:17](../../ai-config/install.sh#L17): `link()` is generalized to source/target and backs up to `~/.claude/backups/`. `ln -sfn` is used. Skills, agents and the hook are linked. [install.sh:32](../../ai-config/install.sh#L32) `register_gate_hook()` adds the hook to settings.json once, with a backup.
- [ai-config/skills/commit-review/SKILL.md:1](../../ai-config/skills/commit-review/SKILL.md#L1): new `/commit-review` skill.
- [ai-config/skills/handoff/SKILL.md:1](../../ai-config/skills/handoff/SKILL.md#L1): new `/handoff` skill (manual only, `disable-model-invocation: true`), including the legacy `HANDOFF.md` migration and the resume prompt.
- [ai-config/agents/commit-reviewer.md:1](../../ai-config/agents/commit-reviewer.md#L1): new read-only reviewer subagent and the review-file template.
- [ai-config/docs/feature-review.md:18](../../ai-config/docs/feature-review.md#L18): adds `/commit-review` and the gate, the stale-review rule, and the Not tested / Checklist / Findings sections.
- [ai-config/docs/documentation-standards.md:86](../../ai-config/docs/documentation-standards.md#L86): adds per-session handoff files, the HANDOFF.md index and the resume prompt.
- [ai-config/docs/before-starting.md:5](../../ai-config/docs/before-starting.md#L5): new sessions read the latest linked handoff.
- [ai-config/docs/commit-messages.md:13](../../ai-config/docs/commit-messages.md#L13): step 9 now names `/commit-review`.
- [ai-config/AGENTS.md:1](../../ai-config/AGENTS.md#L1): regenerated. It matches the `build.sh` output for the staged docs.
- [ai-config/README.md:27](../../ai-config/README.md#L27): adds the folder layout, the skills/agents/hooks table, the gate rules and limits, and updated install and workflow notes.

## What was fixed
Feature work. Bugs fixed along the way are visible in the code and tests: bash 3.2 empty-array `set -u` handling (`${args[@]+...}`), heredoc and quoted-message false positives, and fail-closed exit 2 on internal errors. No other fixes.

## Coverage
| Scenario / flow | Handled by | Proven by |
|---|---|---|
| Non-commit Bash commands pass through without logging | [commit-review-gate.sh:64](../../ai-config/hooks/commit-review-gate.sh#L64) | "non-commit command", "git commit-tree", "git log --grep commit" |
| Quoted or heredoc text that mentions git commit/add/-a/-C is ignored | [commit-review-gate.sh:52](../../ai-config/hooks/commit-review-gate.sh#L52) | "echo mentioning git commit", the heredoc tests, "escaped quotes in -m", "-la in message is not -a" |
| Staged code without a review is denied | [commit-review-gate.sh:177](../../ai-config/hooks/commit-review-gate.sh#L177) | "staged code, no review", "plain git commit, no review", "git commit;" |
| Staged code with a review (root or subproject) is allowed | [commit-review-gate.sh:14](../../ai-config/hooks/commit-review-gate.sh#L14) | "staged code + review", "subproject review" |
| `git -C <literal>` resolves the repo; a variable path is denied | [commit-review-gate.sh:87-99](../../ai-config/hooks/commit-review-gate.sh#L87) | "-C from another dir", "-C quoted path", "-C with a variable path" |
| Quoted `-C` when an earlier command in the same line also has a quoted `-C` | [commit-review-gate.sh:89](../../ai-config/hooks/commit-review-gate.sh#L89) | **Broken.** See Finding 1 (manual probe) |
| Staging in the same command is denied | [commit-review-gate.sh:106](../../ai-config/hooks/commit-review-gate.sh#L106) | "add && commit", "-C add && -C commit" |
| Pathspec, `--only`, `--include` and `--` commits are denied | [commit-review-gate.sh:114-145](../../ai-config/hooks/commit-review-gate.sh#L114) | "pathspec with review staged", "-- pathspec", "--only", "--include" |
| `-a`/`--all` includes tracked unstaged files | [commit-review-gate.sh:153](../../ai-config/hooks/commit-review-gate.sh#L153) | "-am with modified review", "-a, review unchanged", "-C with -am" |
| Amend or allow-empty with nothing staged; amend of a reviewed HEAD | [commit-review-gate.sh:162-175](../../ai-config/hooks/commit-review-gate.sh#L162) | "message-only amend", "allow-empty", "amend adding code to (un)reviewed HEAD" |
| A deleted review file doesn't count | [commit-review-gate.sh:153](../../ai-config/hooks/commit-review-gate.sh#L153) | "deleted review doesn't count", "delete-only, no review" |
| Internal error after a commit is detected blocks with exit 2 | [commit-review-gate.sh:80](../../ai-config/hooks/commit-review-gate.sh#L80) | "internal error exits 2 (blocks)" |
| jq missing: gate fails open | [commit-review-gate.sh:38](../../ai-config/hooks/commit-review-gate.sh#L38) | untested (documented in README) |
| Install: symlinks, backups, one-time hook registration | [install.sh:17-80](../../ai-config/install.sh#L17) | manual: the live `~/.claude` has the symlinks and exactly one PreToolUse Bash entry |
| `/handoff` and `/commit-review` skill flows, reviewer output format | SKILL.md and agent files | manual only (prompt files; can't be unit-tested) |

## Edge cases
| Edge case | How it's handled | Tested? |
|---|---|---|
| macOS `/bin/bash` 3.2 | Empty-array guard; no bash-4-only features | Yes, the suite passes under `/bin/bash` 3.2 |
| `cd <other repo> && git commit` | Checked against the session cwd. A non-repo cwd gives allow; reviewed repo A as cwd gives allow for repo B | Probed: both allowed. Limitation documented in README |
| `bash -c "git commit"` or `sh -c '...'` | Not detected | Documented, not tested |
| Git alias (`git ci -m x`) | Not detected: allowed | Probed. **Not documented** |
| Unquoted comment `git status # then git commit` | Treated as a commit: false deny | Probed. README covers "unquoted text counts" |
| Two `-C` flags on the commit | The last one is used, so this is denied when that repo is unreviewed | Probed |
| Review filename with non-ASCII characters | `core.quotePath` quotes the name, so the regex misses it: false deny (fails closed) | Probed. A space-only name is allowed. The skill only produces kebab-case slugs |
| `--git-dir`/`--work-tree` | Detected; repo resolved from cwd | Detection tested; resolution documented as a limit |
| Merge, cherry-pick, revert or rebase commits | Out of scope (only `git commit` is gated) | No |
| Invalid `settings.json` at install | jq fails, the error is printed, `set -e` exits non-zero, and the backup is already taken | No |
| Symlinked `settings.json` | Written in place with `cat >` so the symlink is kept | No |

## Not tested
- **Behavior of `install.sh` against a fresh or conflicting `~/.claude`.** It's acceptable for this commit: the script is idempotent and the live install shows the expected end state. A follow-up could run it with a temporary `HOME` in a test.
- **The skills and subagent end to end.** They are prompt files, and this review run is their first manual use. That's acceptable.
- **Fail-open when jq is missing.** It's a deliberate, documented choice, and jq is present on this machine.

## Production rollout & downtime
Not a deployed service. It's installed through symlinks on this machine and is already active. Rollback: remove the PreToolUse entry from `~/.claude/settings.json`, or restore the backup taken at install.

## Checklist
### Done
- [x] `/handoff` writes per-session files to `docs/handoffs/`, keeps the `HANDOFF.md` index (Latest plus History), moves a legacy HANDOFF.md aside without losing it, and ends with a one-line resume prompt.
- [x] `/commit-review` runs a fresh-context subagent, writes and stages the review file with coverage, edge cases, Not tested, a done/not-done checklist, findings and a verdict.
- [x] A hook blocks Claude's `git commit` when no review file is staged. It's registered by `install.sh`.
- [x] Hook test suite: all pass under bash 3.2.
- [x] Rule docs updated; `AGENTS.md` regenerated and in sync with `build.sh`.
- [x] README covers the layout, the gate rules and limits, install and workflow.
- [x] No secrets, env files or generated artifacts staged.
### Not done
- [ ] Quoted `git -C` resolution in multi-command lines. Follow-up: Finding 1, which blocks this commit.
- [ ] Git aliases aren't detected and aren't listed in the README gate limits. Follow-up: add one line to the README.
- [ ] Non-ASCII review filenames are falsely denied. This is OK for this commit: it fails closed and the skill generates ASCII slugs.
- [ ] The repo root has no STATUS.md, PROGRESS.md, HANDOFF.md or `docs/`, which the global instructions require. This is OK for this commit: they were already missing and this change doesn't remove anything. Follow-up: add them, or document that this repo is exempt.
- [ ] shellcheck isn't available, so the hook wasn't linted. Follow-up: install shellcheck and lint both scripts.

## Findings
1. **[blocking] A quoted `git -C` path is taken from the wrong git invocation, so an unreviewed commit is allowed.** At [commit-review-gate.sh:88-90](../../ai-config/hooks/commit-review-gate.sh#L88), when the commit's own `-C` argument was quoted (and so became `Q`), the fallback picks the *first* `git -C "..."` in the whole raw command (`head -n1`). That isn't necessarily the one on the commit. Scenario, reproduced: repo A has code and a review staged, repo B has code staged with no review, and cwd is outside both. The command `git -C "<A>" status && git -C "<B>" commit -m x` is **ALLOWED** because A's index is checked. The opposite mix gives a false deny. The comment at line 83 says the commit invocation's own `-C` wins, and the test "-C quoted path" claims to cover quoted paths. So this is wrong behavior in something the change says it handles, and it fails open. Fix: match the quoted path only where it is attached to the commit. One way is to anchor the raw-command regex on `-C[[:space:]]+("[^"]+"|'[^']+')` followed by optional global options and `[[:space:]]+commit`. Another is to use the Nth quoted `-C`, where N counts the `Q` placeholders before the commit in `$bare`. Failing that, deny when more than one quoted `-C` exists. Add a test for this exact two-repo command.
2. **[non-blocking] `cd <repoB> && git commit` is checked against the session cwd.** If cwd is a non-repo, or a repo that already has a review staged, an unreviewed commit in B is allowed (probed). This is documented in the README, but it's a common pattern. Suggested fix: parse a leading `cd <literal>` segment just before the commit the same way `-C` is handled, or deny when a `cd` precedes the commit.
3. **[non-blocking] Git aliases bypass detection.** `git ci -m x` with code staged and no review is allowed (probed). Suggested fix: add it to the README gate limits, or resolve aliases with `git config --get-regexp '^alias\.'`.
4. **[non-blocking] Review filenames with non-ASCII characters give a false deny.** `--name-status` quotes them under `core.quotePath`, so `\.md$` fails (probed: `é x.md` is denied, `a b.md` is allowed). It fails closed. Fix: `git -c core.quotePath=false diff ...`, or `-z` parsing.

## Tests & checks run
- `bash ai-config/hooks/test-commit-review-gate.sh` (default `bash` is `/bin/bash` 3.2.57): all tests passed.
- The same suite with `PATH=/bin:/usr/bin:<jq dir> /bin/bash ...`: all tests passed.
- Rebuilt `AGENTS.md` from the staged `docs/*.md` in `build.sh` ORDER into the scratchpad and diffed it against the staged `AGENTS.md`: in sync.
- A manual probe matrix ran against throwaway repos in the scratchpad: cd bypass (allowed), quoted `-C` mismatch (allowed, Finding 1), two `-C` (denied), comment mention (denied), `--no-verify`, `-m"x"`, `--message=x`, `-qm`, `\git`, `command git`, trailing `--`, two `-m`, `-F file`, glued redirect (all denied as expected without a review), `git ci` (allowed), non-ASCII review name (denied), space-only review name (allowed).
- The live installed hook denied one of my own probe commands (a loop using `git -C $S/$r commit`, a variable path), which confirms the gate is active and denies unresolvable `-C` paths.
- Checked `~/.claude/settings.json` read-only: there is exactly one PreToolUse Bash entry for the gate. The skill, agent and hook symlinks point into the repo.
- shellcheck and shfmt are not installed, so no lint was run.

## Risks & follow-ups
- The gate is a guardrail against forgetting, not a security boundary. Several documented paths get around it (`cd`, `bash -c`, aliases, `--git-dir`), and it checks only that a review file is present, not that it is current.
- The hook runs on every Bash call (two jq invocations plus awk, sed and grep). The cost is small, but a hook error before commit detection fails open.
- Fix Finding 1, add the regression test, and re-run `/commit-review` before committing.

---

## Resolution (added by the implementer after this review, not by the reviewer)

This review's BLOCK verdict stands as written above. The user explicitly
approved committing with this review plus the fixes below **as a one-time
exception**, instead of running a fifth review. The fixes were **not**
re-reviewed by a fresh reviewer.

Earlier review rounds (not kept as files) blocked on, and led to fixes for:
pathspec commits bypassing the gate; heredoc messages with quotes being
misparsed; plain `git commit` crashing the hook under bash 3.2 (fail-open);
`git -C` text inside commit messages changing the checked repo.

| Finding | Resolution | Proven by |
|---|---|---|
| 1 (blocking) quoted `-C` taken from the wrong invocation | The hook now denies when the commit's `-C` is quoted and the command contains anything other than exactly one quoted `git -C`. | test "two quoted -C paths (ambiguous)" |
| 2 `cd <repo> && git commit` checked against session cwd | A literal `cd <path>` before the commit now sets the repo (then `-C` applies on top). Quoted or variable `cd` paths, and `cd` to a non-repo, are denied. | tests "cd <repo> && commit + review", "cd <non-repo> && commit", "cd quoted path && commit", "cd variable && commit" |
| 3 git aliases not detected | Documented in the README gate limits (not fixed). | — |
| 4 non-ASCII review filenames falsely denied | Diff calls now use `git -c core.quotePath=false`. | test "non-ASCII review filename" |

After the fixes: `/bin/bash ai-config/hooks/test-commit-review-gate.sh` →
57/57 pass (bash 3.2.57). The README gate rules were updated to describe the
`cd`/`-C` resolution order and the alias and subshell-`cd` limits.

Still open (unchanged from the checklist above): jq-missing fail-open,
`bash -c` and aliases undetected, stale reviews not detected, no shellcheck
run, and no STATUS/PROGRESS/HANDOFF files at the dotfiles repo root.
