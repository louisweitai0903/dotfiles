# Review: Add frontend layout and component reuse rules to ai-config

- **Date:** 2026-11-18
- **Branch:** docs/frontend-standards (HEAD 555d2b6, base main)
- **Verdict:** PASS

## Summary
Adds a new rule file, `ai-config/docs/frontend-standards.md`, with two sections the user asked for:
- **Layout & styling:** align things with layout primitives instead of nudging them with padding or margins; take spacing only from design tokens; prefer relative or fluid sizing.
- **Component reuse:** extract shared components instead of copying them; replace page-specific dependencies with props; use props for small variations and composition for large ones; update imports and delete the old copy.

The file is added to the `build.sh` ORDER list right after `frontend-references.md` and listed in the README rules table. `AGENTS.md` is rebuilt. `~/.claude/CLAUDE.md` is a symlink to that file, so the rules take effect in every session as soon as this merges.

## Files changed
- [ai-config/docs/frontend-standards.md:1](../../ai-config/docs/frontend-standards.md#L1): new source file holding the two rule sections.
- [ai-config/build.sh:21](../../ai-config/build.sh#L21): `frontend-standards.md` added to `ORDER`, after `frontend-references.md`.
- [ai-config/AGENTS.md:298](../../ai-config/AGENTS.md#L298): rebuilt output now includes the new "Frontend Standards" section.
- [ai-config/README.md:121](../../ai-config/README.md#L121): new row in the docs table.

## What was fixed
None. This adds new rules and fixes no bug.

## Coverage
| Scenario / flow | Handled by | Proven by |
|---|---|---|
| Layout rule: use primitives, not nudges | [frontend-standards.md:5](../../ai-config/docs/frontend-standards.md#L5) | manual: matches the user's wording |
| Spacing only from tokens | [frontend-standards.md:8](../../ai-config/docs/frontend-standards.md#L8) | manual |
| Relative/fluid sizing | [frontend-standards.md:10](../../ai-config/docs/frontend-standards.md#L10) | manual |
| Extract shared components instead of duplicating | [frontend-standards.md:15](../../ai-config/docs/frontend-standards.md#L15) | manual |
| Page-specific dependencies become props | [frontend-standards.md:17](../../ai-config/docs/frontend-standards.md#L17) | manual |
| Props for small variations, composition for large | [frontend-standards.md:19](../../ai-config/docs/frontend-standards.md#L19) | manual |
| Update imports and delete the old copy | [frontend-standards.md:21](../../ai-config/docs/frontend-standards.md#L21) | manual |
| `AGENTS.md` matches what `build.sh` produces | [build.sh:21](../../ai-config/build.sh#L21) | rebuilt in the scratchpad from HEAD and diffed against the committed file: identical |

## Edge cases
| Edge case | How it's handled | Tested? |
|---|---|---|
| Committed `AGENTS.md` out of sync with docs/ | Rebuilt from HEAD and diffed | Yes: identical |
| `margin-inline: auto` looks like it breaks the "no margins for alignment" rule | Named explicitly as an allowed layout primitive | n/a |
| Reuse rule pulling against scope-control ("don't reorganize unrelated files") | The rule only applies when the component is needed elsewhere, so the move is part of the task. This also matches "apply once real reuse exists" in implementation-standards | n/a |
| Projects with no spacing scale or design tokens | Not covered; the rule assumes tokens exist | n/a |

## Not tested
- **Agent behavior under the new rules.** These are prose instructions, so there is nothing automated to test. Acceptable for a docs/config repo.

## Production rollout & downtime
Not a live product. Note that `~/.claude/CLAUDE.md` is a symlink to `ai-config/AGENTS.md`, so the rules apply to all agent sessions as soon as the file on disk changes. Rollback is reverting the commit; a rebuild is not needed because `AGENTS.md` is committed.

## Checklist
### Done
- [x] Both requested rule sections added, faithful to the request
- [x] Source file in `docs/`, registered in `build.sh` ORDER
- [x] `AGENTS.md` regenerated and matching the build output
- [x] README docs table updated
### Not done
- [ ] STATUS.md / PROGRESS.md updates. OK for this PR because neither file exists in this repo, and earlier ai-config branches didn't add them either.
- [ ] Fallback for projects without design tokens. OK for this PR because the user didn't ask for one; it could be a later refinement.

## Findings
No findings.

## Tests & checks run
- Copied `build.sh` and `docs/*.md` from HEAD into the scratchpad, ran `build.sh` there, and ran `diff` against `git show HEAD:ai-config/AGENTS.md`. Result: identical (24 docs).
- Searched with `grep` for other places that list the docs files. Only `README.md` and `build.sh` do, and both are updated.
- No test suite or linter exists for `ai-config`.

## Risks & follow-ups
- "No arbitrary pixel values" and "only with values from the project's spacing scale" give no guidance for projects that have no tokens. An agent may stall or make up a scale. Consider adding a fallback such as "if no scale exists, use the framework's default scale (e.g. Tailwind)".
