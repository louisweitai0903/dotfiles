# Git Workflow: Feature Branches, Decoupled Commits, Draft PRs

Once the plan is approved (or, for small low-risk work that needs no plan
approval per `execution-plan.md`, once the task is clear), work on a
feature branch through to a draft PR without asking per commit. Never
commit to, push to, or merge into `main`, `master`, `dev` or `staging`.

Big or destructive changes still stop for plan approval. That approval is
where this autonomy starts.

## Recommended workflow

1. Understand the task and verify current behavior.
2. **Branch.** From a protected branch, first create `type/slug`, where
   `type` is a Conventional Commit type (e.g. `feat/invoice-export`).
3. Implement in small steps. After each logical change: lint, run tests,
   and commit once they're green and the project's pre-commit hook passes.
4. Update documentation.
5. Run the fresh-session review of the whole branch and commit its review
   file (see `feature-review.md`). In Claude Code, run `/commit-review`.
   Skip this for docs-only branches.
6. **Push** with `git push -u origin HEAD`.
7. **Open a draft PR** and report it (see below).

Never commit unnecessary generated files. If the working tree is clean, do
not create an empty commit.

## Commits

- One logical change per commit, made after a green test run with the
  pre-commit hook passing. Don't bundle unrelated changes.
- Subject: Conventional Commits, `type(scope): subject`, e.g.
  `fix(auth): reject expired refresh tokens`. `type` is feat, fix,
  refactor, docs, test, chore, etc. `scope` is the module or area.
- Body: 2–4 lines covering what changed, why, and the alternatives
  rejected. Wrap around 72 chars.
- A ticket named by the task, branch or prompt goes in a final
  `Refs: TICKET-ID` line, never in the scope.
- Never commit generated files, build artifacts, secrets, or debug/scratch
  files.
- Never skip hooks (`--no-verify`) or bypass signing unless explicitly asked.

## Push

- Only `git push -u origin HEAD`.
- Never `--force`, `-f` or `--force-with-lease`, and never a refspec naming
  a protected branch.

## Draft PR

- `gh pr create --draft` against the branch the work started from
  (`--base <branch>`).
- The PR body includes a summary, test evidence (command and result),
  coverage before and after, and migration or rollback notes where they
  apply.
- Report the branch, the commits (short hash and subject) and the PR link.

## Never without an explicit ask

- Never merge, approve or mark a PR ready (`gh pr merge`, `gh pr ready`,
  `gh pr review --approve`).
- Amend, rebase and reset need an explicit ask.
- Never force-push or rewrite published history (see `safety.md`).
