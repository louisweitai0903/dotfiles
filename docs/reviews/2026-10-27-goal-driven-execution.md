# Review: Goal-driven execution and regression-test rule for ai-config

- **Date:** 2026-10-27
- **Branch:** docs/goal-driven-execution (HEAD b9e33c0, base main)
- **Verdict:** PASS

## Summary
Adds a new modular instruction doc, `goal-driven-execution.md`, built into `AGENTS.md`. It covers four things the user asked for:
- Turn every task into a checkable goal.
- Loop until the check passes, and never skip or weaken tests.
- Turn every behavioral defect caught in a session into a regression test that fails without the fix.
- Report only results you actually ran.

The branch also tightens the related rules to match. `debugging.md` drops the old "when practical" wording. `feature-review.md` and the `commit-reviewer` agent now ask for the regression test behind each fix, so the rule is enforced at review time. Because no "Show the Plan and Impact" doc exists, the per-step plan checks point at the existing `execution-plan.md`.

## Files changed
- [ai-config/docs/goal-driven-execution.md:1](../../ai-config/docs/goal-driven-execution.md#L1): new doc with the checkable-goal mapping, the loop rule, "every error caught becomes a test" and "report the evidence".
- [ai-config/build.sh:17](../../ai-config/build.sh#L17): adds the new doc to `ORDER`, right after `execution-plan.md`.
- [ai-config/AGENTS.md:171](../../ai-config/AGENTS.md#L171): regenerated output with the new section and the debugging/feature-review wording.
- [ai-config/docs/debugging.md:11](../../ai-config/docs/debugging.md#L11): regression test is now required ("fails without the fix and passes with it") instead of "when practical", with an escape hatch that must state a reason.
- [ai-config/docs/feature-review.md:42](../../ai-config/docs/feature-review.md#L42): "What was fixed" must name the regression test for each fix, or say why there is none.
- [ai-config/agents/commit-reviewer.md:32](../../ai-config/agents/commit-reviewer.md#L32): reviewer step 4 treats a fix with no regression test and no stated reason as a finding. The template at [line 64](../../ai-config/agents/commit-reviewer.md#L64) asks for the test.
- [ai-config/README.md:101](../../ai-config/README.md#L101): docs table row for the new file.

## What was fixed
Feature, not a bug fix. The second commit (b9e33c0) refines the first in two ways:
- The rule is limited to behavioral defects, so typos, lint and compile errors don't each need a test.
- The reviewer now checks for the regression test.

This change is prose-only instruction text. No defect in it can be observed by an automated test, so the absence of a regression test is acceptable under the rule's own escape hatch.

## Coverage
| Scenario / flow | Handled by | Proven by |
|---|---|---|
| Agent turns a task into a checkable goal (validation, bug, perf, refactor) | [goal-driven-execution.md:3](../../ai-config/docs/goal-driven-execution.md#L3) | manual read |
| Per-step checks inside the plan | [goal-driven-execution.md:11](../../ai-config/docs/goal-driven-execution.md#L11) refers to `execution-plan.md` | manual read |
| Loop until green; no skipping or weakening tests; coverage does not decrease | [goal-driven-execution.md:14](../../ai-config/docs/goal-driven-execution.md#L14) | manual read |
| Error caught in a session becomes a regression test | [goal-driven-execution.md:21](../../ai-config/docs/goal-driven-execution.md#L21), [debugging.md:11](../../ai-config/docs/debugging.md#L11) | manual read |
| Review enforces the regression-test rule | [commit-reviewer.md:32](../../ai-config/agents/commit-reviewer.md#L32), [feature-review.md:42](../../ai-config/docs/feature-review.md#L42) | manual read |
| Report only evidence that was actually run | [goal-driven-execution.md:33](../../ai-config/docs/goal-driven-execution.md#L33) | manual read |
| Committed `AGENTS.md` matches the `build.sh` output | [build.sh:11](../../ai-config/build.sh#L11) | rebuilt into the scratchpad and compared with `diff`: identical |

## Edge cases
| Edge case | How it's handled | Tested? |
|---|---|---|
| Defect that can't be tested (external service) | Escape hatch: say why in the report and the review file | n/a (prose) |
| Typos, lint or compile errors caught while editing | Explicitly excluded from the rule | n/a |
| Refactor of untested code | Write characterization tests first | n/a |
| Docs-only commits (no tests possible) | The existing docs-only review exemption still applies. The rule only covers behavioral defects | n/a |
| User's "Show the Plan and Impact" doc doesn't exist | Points to `execution-plan.md` instead | n/a |

## Not tested
- **How agents actually follow the new instructions.** This is prose policy, and there is no harness to test it. That is acceptable here; it would only show up in future sessions.
- **"Coverage does not decrease" has no enforcement mechanism** (no coverage tool is required). That is acceptable as a policy statement. A follow-up could add guidance on how to measure coverage.

## Production rollout & downtime
Not live (personal dotfiles), so there is no downtime analysis. Note that the change only takes effect after it is merged into the main checkout at /Users/louis/dotfiles. `~/.claude/CLAUDE.md` is symlinked to that checkout's `ai-config/AGENTS.md`, not to this worktree. If the commit-reviewer agent is installed by symlink or copy, it likewise picks up the change only from the main checkout.

## Checklist
### Done
- [x] New modular doc covering every clause of the pasted policy
- [x] Regression-test-per-caught-error rule (the user's explicit addition)
- [x] `build.sh` ORDER updated, and `AGENTS.md` matches the build output
- [x] `debugging.md` and `feature-review.md` made consistent with the new rule
- [x] Reviewer agent enforces the rule
- [x] `ai-config/README.md` docs table updated
- [x] Existing hook tests still pass
### Not done
- [ ] No STATUS.md, PROGRESS.md or HANDOFF.md at the repo root. OK for this PR because the earlier ai-config commits on main didn't add them either; it is a pre-existing gap, not caused by this change.
- [ ] `execution-plan.md` itself does not mention per-step checks (the link only runs from the new doc to it). OK because both are concatenated into the same `AGENTS.md`.

## Findings
1. **[non-blocking] Commit subjects break the repo's own commit format.** Both commits use `docs(ai-config): ...` and `fix(ai-config): ...`. `commit-messages.md` and every recent commit on main use `type[subject] -- summary`, for example `feat[ai-config] -- add per-project daily task list ...`. As a result, `git log --oneline` mixes two styles, and anything that parses the `type[subject]` format will misread these commits. Suggested fix: reword the subjects before merging, e.g. `docs[ai-config] -- add goal-driven execution and regression-test rule`. That is a local history rewrite of an unpushed branch, so get the user's approval first.
2. **[non-blocking] The branch commits were made before the review, and no review file is included.** Both commits touch non-doc files (`build.sh`, `agents/commit-reviewer.md`). Under `feature-review.md`, commits like these need a `docs/reviews/*.md` file in the same commit, so the branch currently breaks the review-before-commit rule. Suggested fix: add this review file, ideally folded into the branch with the reworded commits from Finding 1 (again with approval), or at minimum as a follow-up commit.

## Tests & checks run
- Rebuilt `AGENTS.md` into the scratchpad with the `build.sh` ORDER and compared it with `diff` against the committed `ai-config/AGENTS.md`: identical. I did not run `build.sh` itself, because it writes `AGENTS.md` in place.
- `bash -n ai-config/build.sh`: syntax OK.
- `bash ai-config/hooks/test-commit-review-gate.sh`: "All tests passed". This is a regression check only; the change doesn't touch the hook.
- `grep` for `goal-driven-execution.md` references: found in `README.md`, `debugging.md`, `feature-review.md` and `commit-reviewer.md`. All references point at a file that exists.

## Risks & follow-ups
- Stricter rule: a reviewer may now raise findings on fixes that have no regression test. If this proves noisy, the escape hatch wording ("say why") is the place to adjust.
- "Coverage does not decrease" has no measurement guidance. Consider saying how to check it per language, for example in `testing.md`.
- The change takes effect for global agent behavior only after merging into the main dotfiles checkout.
