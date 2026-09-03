# Commit Messages & Git Practices

## Recommended workflow

1. Understand the task.
2. Verify current behavior.
3. Implement changes.
4. Run linting.
5. Run tests.
6. Verify functionality.
7. Review diff.
8. Update documentation.
9. Commit.

Never commit unnecessary generated files. Only create a checkpoint commit
when there are actual staged or unstaged changes to preserve; if the working
tree is clean, do not create an empty commit.

## Writing the message

- Subject line in imperative mood ("Add", "Fix", "Refactor" — not "Added",
  "Fixes"), no trailing period, roughly 50 characters.
- Favor explaining *why* the change was made over restating *what* changed —
  the diff already shows what changed.
- Add a body when the subject alone isn't enough context: what changed, why,
  and anything a future reader would need. Wrap body lines around 72 chars.
- One logical change per commit. Don't bundle unrelated changes into a single
  commit just because they happened in the same session.
- Never commit generated files, build artifacts, secrets, or debug/scratch
  files.
- Reference issue/ticket IDs when applicable instead of restating their
  contents at length.

## When to commit

- Only commit when explicitly asked to. Making changes is not the same as
  being asked to commit them.
- Never skip hooks (`--no-verify`) or bypass signing unless explicitly asked.
- Never force-push, reset --hard, or rewrite published history without
  explicit approval (see `safety.md`).
