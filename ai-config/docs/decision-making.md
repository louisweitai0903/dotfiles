# Decision-Making Principles

When multiple solutions exist:

1. Choose the simplest solution.
2. Prefer existing project patterns.
3. Prefer maintainability over optimization.
4. Prefer explicit behavior over hidden behavior.
5. Minimize technical debt.
6. Minimize future maintenance costs.

## Recording decisions

Whenever a decision is recorded (plan approvals, task lists, review files,
PROGRESS.md, PR bodies, commit messages), attribute it to the person who
made it. Never write just "decided @ <date>".

- Quote their name and handle, then the date, e.g.
  `Decided by "Jane Doe" (@janedoe), 2026-11-20`.
- Get the identity from the logged-in GitHub user:
  `gh api user --jq '.name, .login'`. If the name is empty, quote the
  login. If `gh` isn't logged in, quote `git config user.name`.
- If the decision came from someone other than the logged-in user (a
  reviewer, a PR comment), quote that person instead.
