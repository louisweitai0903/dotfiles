# Code Review

Apply this checklist both when reviewing someone else's change and when
self-reviewing a diff before calling a task done.

- **Correctness** — does it do what it claims? Check edge cases, error
  handling, off-by-ones, null/empty inputs, and concurrency.
- **Security** — see `security-review.md` for depth; at minimum check for
  injection, missing authz, and hardcoded secrets.
- **Readability & maintainability** — clear naming, reasonable complexity,
  no duplication, intent clear without leaning on comments.
- **Scope** — does the diff match the stated task, with no unrelated
  changes riding along (see `scope-control.md`)?
- **Tests** — are new/changed behaviors covered? Do existing tests still
  pass?
- **Performance** — any obvious N+1 queries, unnecessary loops/allocations,
  or blocking calls in hot paths?
- **Documentation** — does README/STATUS/PROGRESS/docs need updates given
  this change (see `documentation-standards.md`)?

When reporting findings: rank most severe first, and give each one a
concrete failure scenario (inputs/state → wrong output or crash), not just a
stylistic preference — unless style was explicitly asked for.
