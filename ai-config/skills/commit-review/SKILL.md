---
name: commit-review
description: Fresh-context review of a feature branch before its draft PR. Runs the commit-reviewer subagent on the branch diff against its base, writes docs/reviews/YYYY-MM-DD-<slug>.md (coverage, edge cases, untested areas and why, done/not-done checklist) and commits it on the branch. Use before `gh pr create` for any branch that changes code — a hook blocks such PRs without a committed review file. Not needed for docs-only branches.
argument-hint: "[feature-slug]"
---

# /commit-review

Review the whole feature branch, in a fresh subagent that has none of this
session's context, and record the result as a review file committed on the
branch before the draft PR. Implements `docs/feature-review.md` and
`docs/commit-messages.md` from the global instructions.

## Steps

1. **Check the branch.** Run `git rev-parse --show-toplevel` and
   `git branch --show-current`.
   - On `main`, `master`, `dev` or `staging`: stop. Work belongs on a
     `type/slug` branch (see `docs/commit-messages.md`).
   - Base = the branch the work started from (the PR's `--base`). If it
     isn't clear, use `origin`'s default branch
     (`git symbolic-ref --short refs/remotes/origin/HEAD`).
   - Uncommitted changes: commit the finished ones first (one logical change
     per commit) or leave them out. Only committed work is reviewed.
   - `git diff --stat <base>...HEAD`. If the branch covers more than one
     feature/fix: stop and tell the user. One branch, one review, one PR.
   - Every changed file is documentation (`.md`, `.mdx`, `.markdown`,
     `.rst`, `.txt`, `.adoc`, or LICENSE/CHANGELOG/AUTHORS/NOTICE-style
     files): stop. No review is needed; the gate allows docs-only PRs.

2. **Pick the file path.** Slug = `$ARGUMENTS` if given, otherwise a short
   kebab-case name for the change (e.g. `auth-refresh-token-expiry`).
   Path = `docs/reviews/$(date +%Y-%m-%d)-<slug>.md` under the repo root.
   Re-reviewing the same branch overwrites the same file.

3. **Run the reviewer.** Use the Agent tool with
   `subagent_type: "commit-reviewer"`. Give it only:
   - the repo root path and the base ref (it reviews `<base>...HEAD`);
   - what the user asked for, in their words (the goal, not your approach);
   - whether the product is live in production, if known;
   - the review file path, so its links are relative to `docs/reviews/`.

   Do **not** pass your reasoning, your own assessment, known shortcuts, or
   "this is fine because…" — the reviewer must read the change cold.

4. **Write the review.** Save the Markdown it returns to the path from step 2
   exactly as returned (drop only the final `VERDICT:` line). Don't soften,
   reorder, or remove findings.

5. **Act on the verdict.**
   - `VERDICT: BLOCK` — don't open the PR. Show the user the blocking
     findings, fix them in new commits, and run `/commit-review` again.
   - `VERDICT: PASS` — commit the review file on its own
     (`docs(review): <slug>`), push with `git push -u origin HEAD`, and
     open the draft PR (see `docs/commit-messages.md`). Give the user a
     short summary: verdict, the not-done/not-tested items, the review file
     path, the branch, the commits and the PR link.

6. **If the branch changes after the review** (new commits), the review is
   stale — run `/commit-review` again before opening the PR. The hook only
   checks that a review file is committed on the branch, not that it's
   current.
