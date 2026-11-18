# Review: Add frontend standards (layout, component reuse, design & interaction) and queue-with-retry rule to ai-config

- **Date:** 2026-11-18
- **Branch:** docs/frontend-standards (HEAD aa2add5, base main)
- **Verdict:** PASS

## Summary
This branch adds a new agent-rules file, `ai-config/docs/frontend-standards.md`, with three sections:
- **Layout & styling:** align with layout primitives rather than nudging with padding or margins; take spacing only from tokens, falling back to the framework's scale and then to a small `--space-*` rem scale; prefer relative or fluid sizing.
- **Component reuse:** extract and share components; page-specific dependencies become props; props for small variations and composition for large ones; update imports and delete the old copy.
- **Design & interaction:** action-led screens with one clear CTA; mobile, tablet and desktop support; icons on mobile, with accessible labels; loading and disabled state on buttons waiting for the backend; one font and one design language.

It also adds a "Large production traffic" bullet to the "Design for failure" section of `implementation-standards.md`. That bullet calls for Redis or a queue, bounded retry with backoff when they are unavailable, then a visible failure or spooling, and never a silent drop. The new file is registered in `build.sh` ORDER and the README docs table, and `AGENTS.md` is regenerated. Together this covers all three user requests.

## Files changed
- [ai-config/docs/frontend-standards.md:1](../../ai-config/docs/frontend-standards.md#L1): new file with the Layout & styling, Component reuse, and Design & interaction sections.
- [ai-config/docs/implementation-standards.md:44](../../ai-config/docs/implementation-standards.md#L44): new "Large production traffic" bullet (queue/Redis with bounded retry, visible failure or spool).
- [ai-config/build.sh:21](../../ai-config/build.sh#L21): `frontend-standards.md` added to ORDER after `frontend-references.md`.
- [ai-config/README.md:121](../../ai-config/README.md#L121): docs table row for `frontend-standards.md`.
- [ai-config/AGENTS.md:302](../../ai-config/AGENTS.md#L302): regenerated output, which includes both additions.
- [docs/reviews/2026-11-18-frontend-standards.md](2026-11-18-frontend-standards.md): this review file. It replaces the stale review that was written at 6a8858e.

## What was fixed
None. The branch adds documentation and rules only and changes no behavior.

## Coverage
| Scenario / flow | Handled by | Proven by |
|---|---|---|
| Request 1: layout primitives, token spacing, fluid sizing | [frontend-standards.md:3](../../ai-config/docs/frontend-standards.md#L3) | manual read against the request |
| Request 1: component reuse rules (extract, props, composition, delete old copy) | [frontend-standards.md:17](../../ai-config/docs/frontend-standards.md#L17) | manual read |
| Request 2: fallback when there is no spacing scale | [frontend-standards.md:10](../../ai-config/docs/frontend-standards.md#L10) | manual read |
| Request 3: CTA-heavy design | [frontend-standards.md:29](../../ai-config/docs/frontend-standards.md#L29) | manual read |
| Request 3: mobile, tablet and desktop | [frontend-standards.md:35](../../ai-config/docs/frontend-standards.md#L35) | manual read |
| Request 3: icons over text on mobile | [frontend-standards.md:37](../../ai-config/docs/frontend-standards.md#L37) | manual read |
| Request 3: Redis or queue with retry when it is down | [implementation-standards.md:44](../../ai-config/docs/implementation-standards.md#L44) | manual read |
| Request 3: loading state on buttons, no duplicate submits | [frontend-standards.md:40](../../ai-config/docs/frontend-standards.md#L40) | manual read |
| Request 3: same font and design language unless told otherwise | [frontend-standards.md:44](../../ai-config/docs/frontend-standards.md#L44) | manual read |
| Committed AGENTS.md matches `build.sh` output | [build.sh](../../ai-config/build.sh) | rebuilt in a scratch copy; output identical to the committed file |
| Every file in docs/ is listed in ORDER | [build.sh:11](../../ai-config/build.sh#L11) | diffed `ls docs` against ORDER; they match |

## Edge cases
| Edge case | How it's handled | Tested? |
|---|---|---|
| Project has no spacing scale | Use the framework's default scale; with no framework, define a `--space-*` rem scale once | n/a (prose rule) |
| Read-only screens under the "always CTA-heavy" request | Deliberately narrowed: no invented CTA on read-only screens, and error screens get a recovery CTA. This is a reasonable reading of the user's "always" | n/a |
| Icon-only controls (accessibility) | `aria-label` is required, and a text label is kept where the icon is ambiguous | n/a |
| Backend error or timeout on a loading button | The button is re-enabled and the error is shown | n/a |
| Redis or queue down | Bounded retry with backoff, then a visible failure or spooling for replay; never a silent drop | n/a |
| User explicitly asks for a different font or style | The "unless the user explicitly says otherwise" exception applies | n/a |

## Not tested
- **How agents behave under the new rules.** These are prose instructions, and there is no harness for checking agent compliance. That is acceptable for a personal config repo.

## Production rollout & downtime
Not a live product. Note that `~/.claude/CLAUDE.md` is a symlink to `ai-config/AGENTS.md` in this working tree, so the rules apply to new sessions as soon as this branch is checked out, before merge. To roll back, check out main or revert.

## Checklist
### Done
- [x] Layout & styling rules (request 1)
- [x] Component reuse rules (request 1)
- [x] Spacing-scale fallback (request 2)
- [x] CTA, responsive, mobile icons, loading buttons, font and design-language rules (request 3)
- [x] Redis/queue with retry-on-outage rule (request 3)
- [x] Source edited in `docs/*.md`, and `AGENTS.md` regenerated so it matches `build.sh` output exactly
- [x] README docs table updated
### Not done
- [ ] STATUS.md / PROGRESS.md: OK for this PR because the repo has neither file, and adding them is out of scope.

## Findings
1. **[non-blocking] The loading-button rule treats disabling the button as duplicate protection.** The rule at [frontend-standards.md:40](../../ai-config/docs/frontend-standards.md#L40) says repeated clicks "can't fire duplicate requests", but disabling only covers one button in one tab. Failure scenario: a user submits a claim or payment form, the network times out, and the rule re-enables the button. The user then clicks again (or submits from a second tab) while the first request did reach the server, so two records are created. "Design for failure" already mentions idempotent operations in general. Suggested fix: add "and make the backend endpoint idempotent (e.g. an idempotency key) for writes" to this bullet. A related minor point: prefer `aria-disabled` plus a guard over the `disabled` attribute, so screen-reader focus isn't lost.

## Tests & checks run
- `git archive HEAD ai-config | tar -x` into the scratchpad, then `bash build.sh` there and `diff` against the committed `ai-config/AGENTS.md`: IDENTICAL.
- `ls ai-config/docs` compared with the `build.sh` ORDER entries: all 24 files are listed, none missing.
- `bash -n ai-config/build.sh`: syntax OK.
- shellcheck: not installed, so not run.

## Risks & follow-ups
- The rules go live for every agent session as soon as this branch is checked out, because of the symlink.
- Optional: add the idempotency clause to the loading-button rule (Finding 1).
