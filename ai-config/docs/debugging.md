# Debugging

- Reproduce the bug before attempting a fix. If it can't be reproduced, say
  so explicitly rather than guessing at a fix.
- Isolate the smallest input or state that triggers it.
- Form a hypothesis about the root cause and verify it (logs, breakpoints,
  targeted prints) before changing code — don't shotgun-debug by changing
  things and hoping.
- Fix the root cause, not the symptom. If only a workaround is possible,
  say so and explain why.
- Add a regression test that would have caught the bug, when practical.
- Verify the fix resolves the original repro and doesn't break related
  behavior.
