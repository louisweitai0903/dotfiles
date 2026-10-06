# Pre-Commit Feature Review

Every completed feature or bug fix gets an independent review, written up
as a Markdown file, **before** it is committed.

## Fresh-session review

- Run the review in a new session with no context carried over from the
  implementation (in Claude Code, spawn a subagent; elsewhere, start a new
  chat/session). The reviewer should read the code and diff cold, not
  inherit the implementer's assumptions.
- Review each feature or fix **individually**. If a session produced more
  than one, run one review per feature, each with its own review file.
- If a fresh session can't be started in the current tool, say so
  explicitly and do the review as a separate, clearly marked pass.
- If the review finds a real defect, fix it and re-review before
  committing. Don't commit over an open finding.

## Review file

Write one file per feature at `docs/reviews/YYYY-MM-DD-<feature-slug>.md`
in the project, and include it in the feature's commit. It must contain:

- **Summary** — what the feature/fix is, in a few sentences.
- **Files changed** — every touched file as a relative Markdown hyperlink,
  pointing at the relevant lines where useful, e.g.
  `[src/auth/token.ts:42](../../src/auth/token.ts#L42)`, with one line on
  what changed in each.
- **What was fixed** — for bug fixes: the root cause, the symptom, and how
  the fix addresses the cause. For features: any bugs found and fixed
  along the way.
- **Coverage** — the scenarios, inputs, and user flows this change now
  handles, and the tests that prove each one.
- **Edge cases** — edge cases considered, how each is handled, and any
  that are knowingly **not** handled (with the reason).
- **Production rollout & downtime** — if the product is already live:
  expected downtime (or "zero downtime" and why), migrations and their
  locking/duration impact, required deploy order across services,
  config/env changes, feature flags, and the rollback procedure. If the
  product is not live yet, state that and skip the downtime analysis.
- **Risks & follow-ups** — anything remaining that the user should know
  before shipping.
