# Pre-PR Feature Review

Every feature or bug fix gets an independent review, written up as a
Markdown file, **before** its draft PR is opened. The review covers the
whole branch compared with its base, once. Individual commits on the
feature branch don't need their own review.

Docs-only branches are exempt: if every changed file is documentation
(`.md`, `.mdx`, `.markdown`, `.rst`, `.txt`, `.adoc`, or LICENSE/CHANGELOG/
AUTHORS/NOTICE-style files), open the PR without a review. Any other file
on the branch — code, config, scripts — means it needs one.

## Fresh-session review

- Run the review in a new session with no context carried over from the
  implementation (in Claude Code, spawn a subagent; elsewhere, start a new
  chat/session). The reviewer should read the code and diff cold, not
  inherit the implementer's assumptions.
- Review each feature or fix **individually**: one branch, one review, one
  review file.
- If a fresh session can't be started in the current tool, say so
  explicitly and do the review as a separate, clearly marked pass.
- If the review finds a real defect, fix it in a new commit and re-review
  before opening the PR. Don't open a PR over an open finding.
- In Claude Code, run it with `/commit-review`: it hands the branch diff to
  the `commit-reviewer` subagent (fresh context, no edits), writes the
  review file below, and commits it on the branch. A PreToolUse hook blocks
  any `gh pr create` Claude runs when the branch has no committed
  `docs/reviews/*.md` file, and any `git commit` on `main`, `master`, `dev`
  or `staging`.
- If the branch gets new commits after the review, the review is stale.
  Run it again before opening the PR.

## Review file

Write one file per feature at `docs/reviews/YYYY-MM-DD-<feature-slug>.md`
in the project, and commit it as the last commit on the feature branch,
before the PR. It must contain:

- **Summary** — what the feature/fix is, in a few sentences.
- **Files changed** — every touched file as a relative Markdown hyperlink,
  pointing at the relevant lines where useful, e.g.
  `[src/auth/token.ts:42](../../src/auth/token.ts#L42)`, with one line on
  what changed in each.
- **What was fixed** — for bug fixes: the root cause, the symptom, and how
  the fix addresses the cause. For features: any bugs found and fixed
  along the way. Name the regression test that covers each one
  (see `goal-driven-execution.md`), or why none could be written.
- **Coverage** — the scenarios, inputs, and user flows this change now
  handles, and the tests that prove each one.
- **Edge cases** — edge cases considered, how each is handled, and any
  that are knowingly **not** handled (with the reason).
- **Not tested** — anything left untested, each with either why it's
  acceptable for this PR or why it needs follow-up work.
- **Production rollout & downtime** — if the product is already live:
  expected downtime (or "zero downtime" and why), migrations and their
  locking/duration impact, required deploy order across services,
  config/env changes, feature flags, and the rollback procedure. If the
  product is not live yet, state that and skip the downtime analysis.
- **Checklist** — `- [x]` for each requirement, behavior, test, and doc
  update that is done; `- [ ]` for each that isn't, with "OK for this
  PR because …" or "Follow-up: …".
- **Findings** — ranked most severe first, each marked blocking or
  non-blocking with a concrete failure scenario, plus the verdict
  (PASS/BLOCK).
- **Risks & follow-ups** — anything remaining that the user should know
  before shipping.
