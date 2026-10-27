---
name: commit-review
description: Fresh-context review of the staged changes before a git commit. Runs the commit-reviewer subagent, writes docs/reviews/YYYY-MM-DD-<slug>.md (coverage, edge cases, untested areas and why, done/not-done checklist) and stages it. Use before committing any code change — a hook blocks such commits without a review file. Not needed for docs-only commits.
argument-hint: "[feature-slug]"
---

# /commit-review

Review what is about to be committed, in a fresh subagent that has none of
this session's context, and record the result as a review file that goes into
the same commit. Implements `docs/feature-review.md` from the global
instructions.

## Steps

1. **Check what's staged.** Run `git rev-parse --show-toplevel` and
   `git diff --cached --stat`.
   - Nothing staged: stage exactly the files for the one feature/fix being
     committed (never `git add -A` blindly; never stage `.env*`, secrets,
     dependency folders, caches, or build output), then continue.
   - Staged changes cover more than one feature/fix: stop and split them —
     one review and one commit per feature.
   - Every staged file is documentation (`.md`, `.mdx`, `.markdown`, `.rst`,
     `.txt`, `.adoc`, or LICENSE/CHANGELOG/AUTHORS/NOTICE-style files): stop —
     no review is needed. Tell the user and commit directly; the gate allows
     docs-only commits.

2. **Pick the file path.** Slug = `$ARGUMENTS` if given, otherwise a short
   kebab-case name for the change (e.g. `auth-refresh-token-expiry`).
   Path = `docs/reviews/$(date +%Y-%m-%d)-<slug>.md` under the repo root.
   Re-reviewing the same change overwrites the same file.

3. **Run the reviewer.** Use the Agent tool with
   `subagent_type: "commit-reviewer"`. Give it only:
   - the repo root path;
   - what the user asked for, in their words (the goal, not your approach);
   - whether the product is live in production, if known;
   - the review file path, so its links are relative to `docs/reviews/`.

   Do **not** pass your reasoning, your own assessment, known shortcuts, or
   "this is fine because…" — the reviewer must read the change cold.

4. **Write the review.** Save the Markdown it returns to the path from step 2
   exactly as returned (drop only the final `VERDICT:` line). Don't soften,
   reorder, or remove findings. Then `git add` the file.

5. **Act on the verdict.**
   - `VERDICT: BLOCK` — do not commit. Show the user the blocking findings,
     fix them, re-stage, and run `/commit-review` again.
   - `VERDICT: PASS` — give the user a short summary: verdict, the
     not-done/not-tested items, and the review file path. Then commit
     (following `docs/commit-messages.md`), including the review file.

6. **If anything changes after the review** (new edits, restaged files), the
   review is stale — run `/commit-review` again before committing. The hook
   only checks that a review file is staged, not that it's current.
