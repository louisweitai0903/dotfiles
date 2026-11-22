# Code Review

Apply this checklist both when reviewing someone else's change and when
self-reviewing a diff before calling a task done.

- **Correctness** — does it do what it claims? Check edge cases,
  off-by-ones, null/empty inputs, and concurrency.
- **Failure handling** — does the change handle failure well rather than
  assume it won't happen (see "Design for failure" in
  `implementation-standards.md`)? Check that I/O, network, parsing and
  external calls are handled; errors aren't swallowed or caught too
  broadly; a failure leaves data consistent and state recoverable (no
  partial writes, leaked resources, or stuck loading states); timeouts and
  retries are bounded; and users see a clear message while logs keep the
  detail.
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
- **Frontend / screen sizes** — for UI changes, check against
  `frontend-standards.md`: the layout works on mobile (~360px), tablet
  (~768px) and desktop (~1280px+) with no horizontal overflow or clipped
  content; it uses relative sizing and the project's breakpoints; touch
  targets are usable on mobile; empty, loading, error and long-text states
  render correctly. Say whether this was checked by rendering at each
  width or only by reading the code.
- **Documentation** — does README/STATUS/PROGRESS/docs need updates given
  this change (see `documentation-standards.md`)?

When reporting findings: rank most severe first, and give each one a
concrete failure scenario (inputs/state → wrong output or crash), not just a
stylistic preference — unless style was explicitly asked for.
