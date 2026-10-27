# Review: Feature-branch and draft PR workflow, with the review gate moved from `git commit` to `gh pr create`

- **Date:** 2026-10-27
- **Branch:** feat/branch-pr-workflow (HEAD 052ee0b, base main)
- **Verdict:** PASS

## Summary
This branch adds the user's git workflow policy to the global agent instructions. The policy covers `type/slug` feature branches, Conventional Commits with a 2–4 line body and a `Refs:` line, pushing only with `git push -u origin HEAD`, draft PRs only, and never merging, approving or marking a PR ready. It also changes the review gate the way the user chose in option (a). Commits on feature branches no longer need a review. Commits on `main`/`master`/`dev`/`staging` are denied. `gh pr create` is denied unless it's a draft for the current branch and the branch, compared with its base, adds a committed `docs/reviews/*.md` file. Docs-only branches are exempt. The `/commit-review` skill, the `commit-reviewer` agent, README, Definition of Done and daily-tasks were updated to match, and `AGENTS.md` was rebuilt.

## Files changed
- [ai-config/hooks/commit-review-gate.sh:155](../../ai-config/hooks/commit-review-gate.sh#L155): rewritten. Commits are denied on protected branches (lines 155–170). `gh pr create` is checked for draft, base, `--head`/`--repo` and a review file the branch adds (lines 172–251).
- [ai-config/hooks/test-commit-review-gate.sh:51](../../ai-config/hooks/test-commit-review-gate.sh#L51): tests rewritten for the protected-branch and PR rules (83 cases).
- [ai-config/docs/commit-messages.md:1](../../ai-config/docs/commit-messages.md#L1): replaced with the new policy (branch, commits, push, draft PR, never-without-ask).
- [ai-config/docs/feature-review.md:1](../../ai-config/docs/feature-review.md#L1): the review now happens once per branch, before the PR. The review file is the branch's last commit.
- [ai-config/docs/definition-of-done.md:15](../../ai-config/docs/definition-of-done.md#L15): "done" now means committed on a feature branch, pushed, and opened as a draft PR.
- [ai-config/docs/daily-tasks.md:49](../../ai-config/docs/daily-tasks.md#L49): an item is marked done once its PR is open, and the entry records the PR link.
- [ai-config/skills/commit-review/SKILL.md:14](../../ai-config/skills/commit-review/SKILL.md#L14): reviews `<base>...HEAD`, commits the review file, pushes and opens the draft PR.
- [ai-config/agents/commit-reviewer.md:12](../../ai-config/agents/commit-reviewer.md#L12): the reviewer reads the branch diff instead of the staged diff.
- [ai-config/README.md:49](../../ai-config/README.md#L49): gate rules, gate limits and the "add a preference" steps rewritten for branches and PRs.
- [ai-config/AGENTS.md:497](../../ai-config/AGENTS.md#L497): regenerated. It matches `build.sh` output exactly.

## What was fixed
Feature work. Two bugs were found and fixed on the branch itself (146dfcf, 052ee0b):
- `--head` and `--repo` (including the attached forms `-Hx`/`-Rx` and a global `gh -R x pr create`) let a PR open for a branch or repo the gate never checked. These are now denied.
- Editing or deleting an older review file already on the base counted as "a review". Now only a review file the branch adds (status `A`) counts.
- Non-draft PRs are also denied now.

## Coverage
| Scenario / flow | Handled by | Proven by |
|---|---|---|
| Commit on main/master/dev/staging denied (plain, `-C`, `cd &&`, `-c`, `/usr/bin/git`, `--amend`) | [commit-review-gate.sh:155](../../ai-config/hooks/commit-review-gate.sh#L155) | "commit on main", "-C commit on main from outside", "cd && commit on main", "amend on main", and related cases |
| Initial commit on an unborn protected branch allowed | [commit-review-gate.sh:164](../../ai-config/hooks/commit-review-gate.sh#L164) | "initial commit on unborn main" |
| Commits on a feature branch or detached HEAD allowed, with no review | [commit-review-gate.sh:162](../../ai-config/hooks/commit-review-gate.sh#L162) | "commit on feature branch", "add && commit on feature branch", "commit on detached HEAD" |
| `switch`/`checkout` in the same command as a commit denied | [commit-review-gate.sh:159](../../ai-config/hooks/commit-review-gate.sh#L159) | "switch -c && commit" |
| Branch named like a protected one (`main-fix`) is not protected | [commit-review-gate.sh:19](../../ai-config/hooks/commit-review-gate.sh#L19) | "branch named like main-fix" |
| PR without a review file denied (`--base`, `--base=`, `-B`, default base) | [commit-review-gate.sh:244](../../ai-config/hooks/commit-review-gate.sh#L244) | "PR, no review*", "-Bdev attached, no review vs dev" |
| Review staged but not committed doesn't count | [commit-review-gate.sh:230](../../ai-config/hooks/commit-review-gate.sh#L230) | "PR, review staged but not committed" |
| Deleted or edited older review doesn't count | [commit-review-gate.sh:246](../../ai-config/hooks/commit-review-gate.sh#L246) | "PR, deleted review doesn't count", "PR, edited old review doesn't count" |
| Non-draft and `--draft=false` denied | [commit-review-gate.sh:192](../../ai-config/hooks/commit-review-gate.sh#L192) | "PR, not a draft", "PR, --draft=false wins" |
| `--head`/`--repo` in every flag form denied | [commit-review-gate.sh:174](../../ai-config/hooks/commit-review-gate.sh#L174), [:197](../../ai-config/hooks/commit-review-gate.sh#L197) | regression tests from 146dfcf/052ee0b, plus a manual probe (`-Ho:feat/x`, `gh --repo=o/r pr create`) |
| Quoted, missing or unrelated `--base` denied | [commit-review-gate.sh:206](../../ai-config/hooks/commit-review-gate.sh#L206) | "PR, quoted --base", "PR, unknown --base" |
| Docs-only branch exempt; docs plus code branch is not | [commit-review-gate.sh:237](../../ai-config/hooks/commit-review-gate.sh#L237) | "PR, docs-only branch", "PR, docs + code branch" |
| Review in a subproject's `docs/reviews/` | [commit-review-gate.sh:21](../../ai-config/hooks/commit-review-gate.sh#L21) | "PR, subproject review" |
| Commit and PR in one command denied | [commit-review-gate.sh:99](../../ai-config/hooks/commit-review-gate.sh#L99) | "commit && PR in one command" |
| Internal error blocks the command (fails closed, exit 2) | [commit-review-gate.sh:90](../../ai-config/hooks/commit-review-gate.sh#L90) | "internal error exits 2 (…)" |
| Policy text: branch, commit format, push, draft PR, never merge/approve/ready, amend/rebase/reset need an ask | [commit-messages.md:1](../../ai-config/docs/commit-messages.md#L1) | manual: checked against the user's pasted policy |
| Autonomy also starts for small low-risk work once the task is clear | [commit-messages.md:3](../../ai-config/docs/commit-messages.md#L3) | manual: consistent with execution-plan.md:38 |

## Edge cases
| Edge case | How it's handled | Tested? |
|---|---|---|
| Review committed early, then more code commits (stale review) | Allowed. Documented as a gate limit in README and SKILL step 6 | Manual probe: allowed |
| Stacked branch with no `--base` | Compared with the default branch. Documented in README; the workflow requires `--base` | Not tested |
| `GH_REPO=other/repo gh pr create --draft` | Not detected. The local branch is checked, but the PR goes to another repo (Finding 1) | Manual probe |
| Combined short flags (`-dB dev`) | Not parsed, so denied as a non-draft. Documented | Not tested |
| Output redirects or pipes after `gh pr create` (`2>&1 \| tail`) | Argument parsing stops at the redirect or pipe | Indirectly |
| Push/merge to a protected branch, `--force`, `gh pr merge/ready/review --approve` | Rules are instructions only, not enforced. Documented in README gate limits | Manual probe: `git merge`/`git push origin main` not gated |
| Amend/rebase/reset on a feature branch without an ask | Rules are instructions only. The hook allows `--amend` on feature branches. Not listed in README gate limits (Finding 2) | "amend on feature branch" (allow) |
| `bash -c "…"` wrappers, git/gh aliases | Not detected. Documented | No |
| `jq` missing | Fails open. Documented | No |

## Not tested
- **Stacked-branch default base**: documented, and the policy says to always pass `--base`. Acceptable for this PR.
- **Real `gh` behavior** (whether `gh pr create` pushes on its own, or prompts): the hook only inspects the command line, so this is out of scope. Acceptable.
- **Whether the review is current**: not enforced, and documented. A follow-up could require that no non-review commit comes after the newest review file in `base..HEAD`.
- **shellcheck**: not installed on this machine, so it was not run.

## Production rollout & downtime
Not live in production; this is personal dotfiles. The hook and `AGENTS.md` are symlinked into `~/.claude`, so checking out this branch makes the new policy live on this machine right away. To roll back, check out `main`.

## Checklist
### Done
- [x] Feature branches as `type/slug` from a protected branch, Conventional Commit types
- [x] Commits: one logical change, after green tests with the pre-commit hook passing; `type(scope): subject` with a 2–4 line body (what, why, alternatives rejected); ticket in a final `Refs:` line, never in the scope
- [x] Push only with `git push -u origin HEAD`; never `--force`, `-f`, `--force-with-lease`, or a refspec naming a protected branch
- [x] `gh pr create --draft` against the branch the work started from, with summary, test evidence, coverage before/after, and migration/rollback notes
- [x] Report branch, commits (short hash and subject) and PR link
- [x] Never merge, approve or mark ready; amend/rebase/reset need an explicit ask; big or destructive changes stop for plan approval
- [x] Option (a): review once before the PR; the gate moved to `gh pr create`; review file committed as the branch's last commit
- [x] Autonomy for small low-risk work once the task is clear
- [x] Commits on protected branches denied by the hook
- [x] Skill, agent, README, DoD and daily-tasks updated; `AGENTS.md` regenerated and in sync
- [x] Hook tests updated, and all pass
- [x] The branch's own commits follow the new message format
### Not done
- [ ] Enforce that the review file is the last commit / current. Follow-up; documented as a limit.
- [ ] Enforce the push/merge/approve rules in the hook. OK for this PR: the user asked for the policy, the hook is a guard against mistakes, and README states these rules are instruction-only.
- [ ] Root-level README/STATUS/PROGRESS/HANDOFF for the dotfiles repo. OK for this PR: they don't exist on `main` either, so this change doesn't regress anything.

## Findings
1. **[non-blocking] `GH_REPO` env var gets around the `--repo` denial.** Scenario: a branch with a committed review runs `GH_REPO=other/repo gh pr create --draft --base main`. The gate checks the local branch, finds the review, and allows the command, so a PR opens on a repo the gate never inspected. README says `--repo` is denied "in every form", which overstates the coverage. Suggested fix: deny when `GH_REPO=` appears in `$bare` before the invocation, or when `$GH_REPO` is set in the hook's environment, or list it under Gate limits.
2. **[non-blocking] README gate limits don't mention amend/rebase/reset.** The policy says these need an explicit ask, but the hook allows `git commit --amend` on feature branches (test "amend on feature branch" → allow). README lists push/merge/approve as instruction-only but leaves out amend/rebase/reset, so a reader might assume the hook enforces them. Suggested fix: add them to the instruction-only sentence in [README.md:89](../../ai-config/README.md#L89).
3. **[non-blocking] A stale review passes the gate.** Scenario: review committed, then a code commit, then `gh pr create --draft` → allowed (confirmed by manual probe). This is documented and matches the user's chosen design ("blocks a PR whose branch has no review file"), so it's not a defect. Possible follow-up: deny if any non-review path changes in a commit after the newest added review file.

## Tests & checks run
- `bash ai-config/hooks/test-commit-review-gate.sh`: 83 PASS, then "All tests passed".
- Rebuilt `AGENTS.md` with a scratchpad copy of `build.sh` and diffed it against the committed file: identical.
- Manual probe of the hook in a throwaway repo (scratchpad). Without a review: no-review PRs are denied; `-Ho:feat/x` and `gh --repo=o/r pr create` are denied; the `GH_REPO=` case was denied only because there was no review yet. With a review followed by a later code commit: `gh pr create --draft --base main` is allowed (stale review). On `main`: `git commit`, `--amend`, `command git commit` and `env git commit` are denied; `git merge` and `git push origin main` are not gated.
- `shellcheck`: not available, not run.

## Risks & follow-ups
- Checking out this branch changes the live global policy on this machine immediately, because the files are symlinked.
- The hook guards against agent mistakes but doesn't enforce everything. Push, merge, approve, amend, rebase and reset depend on the agent following instructions.
- A follow-up could enforce review freshness and `GH_REPO`.
