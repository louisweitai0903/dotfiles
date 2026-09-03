# Testing Standards

Testing is mandatory.

Priority order:

1. Existing unit tests
2. Existing integration tests
3. Existing end-to-end tests
4. Manual verification

## Test folder structure

- Every module or function must have a corresponding test folder/file
  (following the project's existing test layout convention, e.g. `tests/`,
  `__tests__/`, `*_test.go` alongside the source, etc.).
- As a module gains more functions, its test folder grows alongside it —
  each new function gets its own test coverage rather than being left
  untested or bolted onto an unrelated test file.
- A task is not done until its new/changed tests pass. Do not mark a task
  complete with failing or skipped tests — fix the code or the test first.

Before considering a task complete:

- Verify requested functionality works.
- Verify existing functionality still works.
- Verify edge cases.
- Verify no regressions were introduced.

If tests cannot be executed, explain why.
