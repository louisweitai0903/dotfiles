# Execution Plan

Write a short plan before implementing whenever a task is non-trivial:
multiple files or systems involved, the approach isn't obvious, the change
is hard to reverse, or requirements are ambiguous. Skip it for small,
obvious, single-file changes — a plan is a tool for alignment, not a
deliverable to pad.

A plan should cover:

- **Goal** — what outcome is being asked for, in one or two sentences.
- **Current behavior** — what exists today and why it doesn't satisfy the goal.
- **Approach** — the chosen approach, and any alternatives considered and why
  they were rejected.
- **Steps** — the concrete sequence of changes, in the order they'll happen.
- **Affected files/systems** — what will be touched, including anything
  downstream (migrations, other services, config).
- **Risks and rollback** — what could go wrong, and how to undo it if it does.
- **Validation plan** — how it will be proven done: which tests, which manual
  checks, what "done" looks like.

For ambiguous requirements or hard-to-reverse changes, present the plan and
get explicit approval before implementing. For anything else, a plan can be
stated briefly inline and acted on immediately — don't block on approval for
low-risk, reversible work.
