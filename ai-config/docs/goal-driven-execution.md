# Goal-Driven Execution

Before starting, turn the task into a goal you can check:

- "add validation" → write tests for the invalid inputs, then make them pass.
- "fix the bug" → reproduce it in a test, then make it pass.
- "make it faster" → measure before and after.
- "refactor X" → tests pass before and after. If X has no tests, first
  write ones that capture how it behaves today.

For multi-step work, give a brief plan with a check for each step. It fits
inside the Execution Plan (see `execution-plan.md`).

## Loop until the check passes

- Run the check, read the output, fix, run it again. Don't declare done on
  "should work".
- Never skip, delete or weaken a test to go green. Coverage does not
  decrease.

## Every error caught becomes a test

Any error found during the session — a bug being fixed, a failure hit
while implementing, or a defect raised in review — gets a regression test
that fails without the fix and passes with it. Future work then catches it
before it ships. Add it in the same change as the fix. If a test truly
can't be written (e.g. it depends on an external service you can't fake),
say so and explain why in the report and the review file.

## Report the evidence

- Report what you ran and what it showed: test counts, measurements,
  output.
- Say plainly what was not verified.
- Never state a number, status or result you didn't get by running
  something. Run it and report the output.
