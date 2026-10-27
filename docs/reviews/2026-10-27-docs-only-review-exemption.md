# Review: Docs-only commits are exempt from the commit-review gate

- **Date:** 2026-10-27
- **Branch:** main (HEAD 6bd4371)
- **Verdict:** BLOCK

## Summary
This change lets commits that contain only documentation skip `/commit-review`. Two things change:
- **The gate hook.** `commit-review-gate.sh` now allows a commit when every changed path matches a new `DOC_PATTERN`. "Every changed path" includes staged files, files added by `-a`, deletions, and both sides of a rename. The pattern covers `.md/.mdx/.markdown/.rst/.txt/.adoc` files, plus LICENSE/CHANGELOG/CHANGES/AUTHORS/CONTRIBUTORS/NOTICE/COPYING-style names.
- **The written rules.** AGENTS.md, the docs/ sources, README and the commit-review skill now describe the exemption.

The test fixture was switched from `app.txt` to `app.py`, because `.txt` now counts as documentation. New docs-only tests were added.

## Files changed
- [ai-config/hooks/commit-review-gate.sh:17](../../ai-config/hooks/commit-review-gate.sh#L17): adds `DOC_PATTERN`. The docs-only allow is at [lines 192-197](../../ai-config/hooks/commit-review-gate.sh#L192), before the review-file check.
- [ai-config/hooks/test-commit-review-gate.sh:114](../../ai-config/hooks/test-commit-review-gate.sh#L114): fixture renamed `app.txt` to `app.py`. Adds 10 docs-only checks (md/mdx, LICENSE/CHANGELOG/txt, mixed, delete, rename, rename to code, `-a`).
- [ai-config/docs/feature-review.md:6](../../ai-config/docs/feature-review.md#L6): exemption paragraph.
- [ai-config/docs/commit-messages.md:14](../../ai-config/docs/commit-messages.md#L14): "Skip this step for docs-only commits."
- [ai-config/AGENTS.md:349](../../ai-config/AGENTS.md#L349): regenerated from docs/ (also [line 421](../../ai-config/AGENTS.md#L421)).
- [ai-config/README.md:45](../../ai-config/README.md#L45): skill table row and the gate-rule bullet at [line 50](../../ai-config/README.md#L50).
- [ai-config/skills/commit-review/SKILL.md:3](../../ai-config/skills/commit-review/SKILL.md#L3): description updated, and a docs-only stop condition added at [line 23](../../ai-config/skills/commit-review/SKILL.md#L23).

## What was fixed
Feature change. No other bugs were fixed along the way.

## Coverage
| Scenario / flow | Handled by | Proven by |
|---|---|---|
| Only .md/.mdx staged → allow | [commit-review-gate.sh:194](../../ai-config/hooks/commit-review-gate.sh#L194) | `docs-only (md, mdx)` |
| LICENSE, CHANGELOG, .txt → allow | [commit-review-gate.sh:17](../../ai-config/hooks/commit-review-gate.sh#L17) | `docs-only (LICENSE, CHANGELOG, txt)` |
| Docs plus code → deny | [commit-review-gate.sh:195](../../ai-config/hooks/commit-review-gate.sh#L195) | `docs + code needs review` |
| Deleting a doc → allow | awk prints every path column | `deleting a doc is docs-only` |
| Rename doc→doc → allow; doc→code → deny | both rename sides are checked | `renaming a doc is docs-only`, `renaming a doc to code needs review` |
| Docs staged, `-a` pulls in modified code → deny | `$changes` includes the unstaged diff when `all=1` | `docs staged, -a adds code` |
| Code file with a doc-like basename (`notice.tsx`, `changes.py`) → should deny | **not handled**: allowed (see Finding 1) | manual probe |
| Agent skips the skill for docs-only work | [SKILL.md:23](../../ai-config/skills/commit-review/SKILL.md#L23), AGENTS.md | untested (prose instruction) |

## Edge cases
| Edge case | How it's handled | Tested? |
|---|---|---|
| Code file named `notice.tsx`, `authors.py`, `changes.py`, `license.js`, `Copying.c` | Wrongly treated as docs. `(\.[^/]*)?$` accepts any extension | Manual probe: all ALLOW (defect) |
| `CMakeLists.txt`, `requirements.txt` | Treated as docs, because `.txt` is in the user's chosen list | Manual probe: ALLOW (in spec) |
| `LICENSE-MIT` | Not matched, so a review is required (fails closed) | Manual probe: DENY |
| Filename containing a tab/newline/quote | git C-quotes the path, so the trailing `"` breaks the match and the commit is denied (fails closed) | Manual probe (tab in a `.md` name): DENY |
| Upper/mixed case (`intro.MDX`, `Copying`) | `grep -i` | `docs-only (md, mdx)` |
| `--amend` with only docs staged, on a HEAD that has no review | Now allowed. The amended commit keeps HEAD's unreviewed code. Before this change it was denied. HEAD can only lack a review if it was committed outside the gate. | untested |
| Nothing staged | Denied earlier, before the docs check | existing `nothing staged` |

## Not tested
- **`--amend` with docs-only staged on an unreviewed HEAD.** Low impact: it can only happen if HEAD was committed outside the gate (e.g. manually by the user). It is still a behaviour change worth noting.
- **The agent following the "skip review" prose in SKILL.md/AGENTS.md.** This is an instruction to the agent, so there is nothing automated to test. The hook would allow the commit anyway.

## Production rollout & downtime
There is no deployed service. The hook is symlinked into `~/.claude` and goes live on this machine as soon as the files change. Nothing needs migrating or configuring. To roll back, revert the commit.

## Checklist
### Done
- [x] The hook allows commits where every changed path (including deletions and both sides of a rename) is documentation.
- [x] Mixed docs+code commits and doc→code renames still require a review.
- [x] `-a` brings unstaged tracked changes into the docs-only decision.
- [x] Tests were added, and the fixture was moved off `.txt` so the existing tests still exercise code paths.
- [x] AGENTS.md matches `build.sh` output from the docs/ sources.
- [x] The README, the skill description and the skill's stop condition describe the exemption.
### Not done
- [ ] Doc-like basenames with code extensions are still treated as docs. Follow-up: Finding 1.
- [ ] The hook header comment ([commit-review-gate.sh:1-4](../../ai-config/hooks/commit-review-gate.sh#L1)) still says every commit needs a review file. Follow-up: add one line about the exemption.
- [ ] STATUS.md / PROGRESS.md / HANDOFF.md not updated. That's acceptable for this commit: none of these files exist in this repo, which predates this change.

## Findings
1. **[blocking] Code files with a doc-like basename skip review.** `DOC_PATTERN`'s second branch, `(^|/)(licen[cs]e|changelog|changes|authors|contributors|notice|copying)(\.[^/]*)?$` at [commit-review-gate.sh:17](../../ai-config/hooks/commit-review-gate.sh#L17), accepts *any* extension after those names.
   - **Failure scenario:** Claude stages only `lib/changes.py`, `app/authors.py`, `src/components/Notice.tsx`, `license.js` or `Copying.c`, then runs `git commit -m x`. The hook allows it and logs `docs-only`. Confirmed in a scratch repo.
   - **Why it matters:** the change's own rules say any code file means a review is required ([AGENTS.md:349](../../ai-config/AGENTS.md#L349), [README.md:50](../../ai-config/README.md#L50)). Names like `changes.py`, `authors.py` and `Notice.tsx` are realistic module and component names.
   - **Suggested fix:** the extension branch already covers `CHANGELOG.md`, `LICENSE.txt` and similar. So the basename branch only needs to match bare names, `(^|/)(licen[cs]e|changelog|changes|authors|contributors|notice|copying)$`. Optionally add `([-_][^/.]*)?` to accept `LICENSE-MIT`. Add deny tests for `src/notice.tsx` and `lib/changes.py`.
2. **[non-blocking] `.txt` covers dependency and build manifests.** `requirements.txt`, `CMakeLists.txt`, `constraints.txt` and `robots.txt` commits skip review. The user explicitly accepted `.txt` in any folder, so this is in spec. It is listed here so the trade-off is visible, since a dependency bump in `requirements.txt` gets no review.
3. **[non-blocking] Docs-only amend can carry unreviewed HEAD code.** `git commit --amend` with only a `.md` staged is allowed even when HEAD has code and no review. Before this change it was denied. Impact is low, because HEAD would already have had to bypass the gate. A possible fix is to apply the docs-only allow to an amend only if HEAD's own files are also docs or reviewed.
4. **[non-blocking] Stale hook header comment.** [commit-review-gate.sh:1-4](../../ai-config/hooks/commit-review-gate.sh#L1) still describes blocking every commit that has no review file. Mention the docs-only exemption there.

## Tests & checks run
- `bash ai-config/hooks/test-commit-review-gate.sh`: 65/65 PASS, "All tests passed". The staged and working-tree copies are identical: nothing is unstaged.
- Copied `ai-config/` to the scratchpad and ran `build.sh` there, then diffed against the staged `AGENTS.md`: identical.
- Scratch-repo probe that pipes hook JSON into the staged hook:
  - ALLOW: `src/notice.tsx`, `app/authors.py`, `lib/changes.py`, `license.js`, `Copying.c`, `CMakeLists.txt`, `requirements.txt`, `docs/guide.md`
  - DENY: `LICENSE-MIT`, a tab-in-name `.md` file
- shellcheck: not installed (`command -v shellcheck` returned nothing), so not run.

## Risks & follow-ups
- Fix the `DOC_PATTERN` basename branch and add regression tests (Finding 1).
- Markdown that works as configuration (AGENTS.md, SKILL.md, agent definitions) now skips review. The user explicitly accepted this, but it means changes to the gate's own rules in this repo can land without review.
- `.txt` manifests skip review (Finding 2).
- Update the hook header comment (Finding 4).

---

## Resolution (added by the implementer after this review, not by the reviewer)

This review's BLOCK verdict stands as written above. The user explicitly
approved committing with this review plus the fixes below **as a one-time
exception**, instead of re-running the review. The fixes were **not**
re-reviewed by a fresh reviewer.

| Finding | Resolution | Proven by |
|---|---|---|
| 1 (blocking) doc-like basenames with code extensions skip review | `DOC_PATTERN`'s name branch now matches only extensionless names: `(^|/)(licen[cs]e\|changelog\|changes\|authors\|contributors\|notice\|copying)$`. `CHANGELOG.md`, `LICENSE.txt` etc. are still covered by the extension branch. `LICENSE-MIT` still requires review (fails closed). | tests "doc-like name with code extension" for `lib/changes.py`, `src/Notice.tsx`, `license.js` (all deny) |
| 2 `.txt` manifests skip review | Kept by the user's choice ("Keep as docs"); now stated explicitly in the README gate rules. | — |
| 3 docs-only amend on unreviewed HEAD | Not changed; low impact (HEAD must already have bypassed the gate). | — |
| 4 stale hook header comment | Header now mentions the docs-only exemption. | — |

After the fixes: `/bin/bash ai-config/hooks/test-commit-review-gate.sh` →
68/68 pass (bash 3.2.57).
