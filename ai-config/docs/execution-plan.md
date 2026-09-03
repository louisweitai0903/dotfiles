# Execution Plan

Write a short plan before implementing whenever a task is non-trivial:
multiple files or systems involved, the approach isn't obvious, the change
is hard to reverse, or requirements are ambiguous. Skip it for small,
obvious, single-file changes — a plan is a tool for alignment, not a
deliverable to pad.

## Research prior art first

Before drafting the plan, search GitHub (issues, PRs, and existing
implementations) for prior approaches to the same problem. Look for:

- Existing libraries, tools, or reference implementations that solve it.
- Issues or PRs where other developers hit problems with those approaches —
  bugs, edge cases, performance traps, abandoned attempts.

Use what's found to steer the approach and avoid known pitfalls. Fold
relevant findings into the **Approach** and **Risks and rollback** sections
below instead of listing them separately. Skip this step when the task has
no meaningful prior art to find (e.g. project-specific logic with no public
analogue) or when a plan itself is being skipped per above.

A plan should cover:

- **Goal** — what outcome is being asked for, in one or two sentences.
- **Current behavior** — what exists today and why it doesn't satisfy the goal.
- **Approach** — the chosen approach, and any alternatives considered and why
  they were rejected. Note relevant prior art and how it shaped the choice.
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
