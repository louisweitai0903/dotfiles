# Review: Add frontend layout/styling and component reuse rules (with spacing fallback) to ai-config

- **Date:** 2026-11-18
- **Branch:** docs/frontend-standards (HEAD 6a8858e, base main)
- **Verdict:** PASS

## Summary
This branch adds a new rule file, `ai-config/docs/frontend-standards.md`, with the two sections the user asked for:
- **Layout & styling:** align elements with layout primitives instead of nudging them with padding or margins; take spacing only from the design tokens or spacing scale; prefer relative or fluid sizing.
- **Component reuse:** extract a shared component instead of duplicating it; turn page-specific dependencies into props; use props for small variations and composition for large ones; update imports and delete the old copy.

A follow-up commit adds the fallback the user asked for. When a project has no spacing scale, the agent uses the framework's default scale. With no framework either, it defines a small set of `--space-*` CSS custom properties in rem once and uses only those.

The file is in `build.sh` ORDER right after `frontend-references.md` and listed in the README docs table. `AGENTS.md` is rebuilt to match.

## Files changed
- [ai-config/docs/frontend-standards.md:1](../../ai-config/docs/frontend-standards.md#L1): new source file with both rule sections. The spacing fallback is at [lines 10-13](../../ai-config/docs/frontend-standards.md#L10).
- [ai-config/build.sh:21](../../ai-config/build.sh#L21): `frontend-standards.md` added to `ORDER`.
- [ai-config/AGENTS.md:298](../../ai-config/AGENTS.md#L298): the rebuilt output now includes the "Frontend Standards" section.
- [ai-config/README.md:121](../../ai-config/README.md#L121): new row in the docs table.
- [docs/reviews/2026-11-18-frontend-standards.md](2026-11-18-frontend-standards.md): this review file. It replaces the earlier review, which was written at 555d2b6 before the fallback commit.

## What was fixed
None. This branch adds rules and fixes no bug. The fallback commit (6a8858e) closes the gap the earlier review raised, where projects without a spacing scale got no guidance. That gap was in prose, so there is no regression test to write.

## Coverage
| Scenario / flow | Handled by | Proven by |
|---|---|---|
| Use layout primitives to align, not padding/margin nudges | [frontend-standards.md:5](../../ai-config/docs/frontend-standards.md#L5) | manual: matches the user's wording |
| Spacing only from the scale or design tokens; no arbitrary px | [frontend-standards.md:8](../../ai-config/docs/frontend-standards.md#L8) | manual |
| Fallback: no project scale → framework default scale | [frontend-standards.md:10](../../ai-config/docs/frontend-standards.md#L10) | manual |
| Fallback: no framework → define `--space-*` custom properties once | [frontend-standards.md:11](../../ai-config/docs/frontend-standards.md#L11) | manual |
| Prefer relative or fluid sizing | [frontend-standards.md:14](../../ai-config/docs/frontend-standards.md#L14) | manual |
| Extract shared components instead of duplicating | [frontend-standards.md:19](../../ai-config/docs/frontend-standards.md#L19) | manual |
| Page-specific dependencies become props | [frontend-standards.md:21](../../ai-config/docs/frontend-standards.md#L21) | manual |
| Props for small variations, composition for large | [frontend-standards.md:23](../../ai-config/docs/frontend-standards.md#L23) | manual |
| Update imports and delete the old copy | [frontend-standards.md:25](../../ai-config/docs/frontend-standards.md#L25) | manual |
| Committed `AGENTS.md` matches the `build.sh` output | [build.sh:21](../../ai-config/build.sh#L21) | rebuilt from `git archive HEAD` in the scratchpad and diffed: identical |
| Every file in docs/ is in ORDER | [build.sh:11](../../ai-config/build.sh#L11) | `ls docs` diffed against the ORDER list: identical (24) |

## Edge cases
| Edge case | How it's handled | Tested? |
|---|---|---|
| Project has no spacing scale or tokens | Two-level fallback: the framework's default scale, then custom properties defined once | n/a (prose) |
| `margin-inline: auto` looks like it breaks the "no margins for alignment" rule | Named explicitly as an allowed layout primitive | n/a |
| Tailwind arbitrary values (`p-[13px]`) | Covered by "No arbitrary pixel values" | n/a |
| Defining a new spacing scale vs scope-control ("no speculative changes") | Only when no scale exists and spacing is needed, and done "once", so the scale stays minimal | n/a |
| Reuse rule vs scope-control ("don't reorganize unrelated files") | Applies only when the component is needed elsewhere, which makes the move part of the task. Matches "apply once real reuse exists" in implementation-standards | n/a |
| Non-CSS UIs (React Native, Flutter, SwiftUI): no CSS custom properties or rem | Not handled explicitly. The examples are web-only, though the "framework default scale" level still applies | n/a. See finding 1 |

## Not tested
- **Agent behavior under the new rules.** These are prose instructions with no automated harness. That is acceptable for a personal agent-config repo.

## Production rollout & downtime
Not a live product. These are personal dotfiles. `AGENTS.md` is symlinked into agent configs (`~/.claude/CLAUDE.md`, and per-project `.github/copilot-instructions.md` through `link-copilot.sh`), so the rules apply as soon as the file on disk changes. Rollback is a revert. No rebuild is needed because `AGENTS.md` is committed.

## Checklist
### Done
- [x] "Layout & styling" section added, faithful to the request
- [x] "Component reuse" section added, faithful to the request
- [x] Spacing-scale fallback added (second request)
- [x] Source file in `docs/`, registered in `build.sh` ORDER
- [x] `AGENTS.md` regenerated and byte-identical to the build output
- [x] README docs table updated
### Not done
- [ ] STATUS.md / PROGRESS.md updates. OK for this PR because neither file exists in this repo.

## Findings
1. **[non-blocking] The fallback and sizing examples are web-only.** If an agent works on a React Native or Flutter project with no spacing scale, the last fallback level (CSS custom properties in rem) and the rem/fr/clamp sizing guidance don't apply. The agent might then invent ad-hoc numbers. Optional fix: generalise the last level to something like "define a small spacing scale once as constants/tokens in the project (e.g. CSS custom properties `--space-1`… in rem for web)".

## Tests & checks run
- Extracted `ai-config` from `git archive HEAD` into the scratchpad, ran `bash build.sh` (output: "Built … from 24 docs."), and diffed the result against `git show HEAD:ai-config/AGENTS.md`. Result: identical.
- Diffed the `ls ai-config/docs` listing against the `.md` entries in `build.sh` ORDER. Result: identical. Every doc is included.
- `git grep frontend-references`: only `README.md` and `build.sh` list the docs files, and both are updated.
- No test suite or linter exists for `ai-config`.

## Risks & follow-ups
- The new rules take effect in every agent session straight away through the symlinked `AGENTS.md`, before and regardless of merge, because the working-tree file is what gets read.
- Web-only examples in the fallback (finding 1). This is an optional wording tweak.
