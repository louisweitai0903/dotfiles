---
name: handoff
description: Write a session handoff to docs/handoffs/handoff-<title>-YYYY-MM-DD-HHMM.md and update the HANDOFF.md index, so the next session can continue without re-discovering this one's work.
argument-hint: "[title]"
disable-model-invocation: true
---

# /handoff

Capture this session's state for the next agent or person. Implements the
HANDOFF rules in `docs/documentation-standards.md` from the global
instructions.

## Steps

1. **Locate the project.** Root = `git rev-parse --show-toplevel`, or the
   current directory if it isn't a git repo. In a git repo, make sure
   `/HANDOFF.md`, `/docs/handoffs/` and `/docs/tasks/` are listed in
   `$(git rev-parse --git-common-dir)/info/exclude`, and add any that are
   missing. Handoffs are local-only and never committed (see "Local-only
   files" in `docs/documentation-standards.md`). If the repo already tracks
   any of them, tell the user rather than untracking it.

2. **Name the file.** Title slug = `$ARGUMENTS` converted to lowercase
   kebab-case (letters, digits, hyphens; at most ~50 characters). With no
   argument, derive a short slug from what this session worked on.
   Path = `docs/handoffs/handoff-<slug>-$(date +%Y-%m-%d-%H%M).md`.

3. **Gather facts — don't rely on memory alone.**
   - `git status --short`, `git branch --show-current`, `git log --oneline -15`,
     and `git diff --stat` / `git diff --cached --stat` for in-flight work.
   - `STATUS.md`, `PROGRESS.md`, and any `docs/reviews/` files from this session.
   - Today's task list, `docs/tasks/$(date +%F).md`, if it exists (see
     `docs/daily-tasks.md` in the global instructions).
   - This conversation: what was asked, what was tried, what failed, what was
     decided and why.

4. **Write the handoff** using this structure. Link files relative to
   `docs/handoffs/` (e.g. `[src/app.ts:10](../../src/app.ts#L10)`). Never
   include secrets, tokens, or `.env` values.

   ```markdown
   # Handoff: <Title>

   - **Date:** YYYY-MM-DD HH:MM
   - **Branch:** <branch> (HEAD <short sha>)
   - **Session goal:** <what the user asked for, in a sentence or two>

   ## Today's tasks
   [docs/tasks/YYYY-MM-DD.md](../tasks/YYYY-MM-DD.md) (local, untracked)
   - Done: <items ticked today, one line each>
   - Open: <items still open>
   <Or "No task list for today.">

   ## Changes this session
   <Core functions, architecture, data flows, commands, and important files
   changed — with links. Note which are committed and which aren't.>

   ## Failed attempts
   - **<what was tried>** — why it didn't work, and what that rules out.
   <Or "None.">

   ## Current status
   <Concise summary of STATUS.md: health, blockers, active work. Say if
   STATUS.md is missing or out of date.>

   ## Recent progress
   <Concise summary of PROGRESS.md: latest completed tasks and the
   validation done for them.>

   ## In-flight work
   <Uncommitted or unstaged changes, half-done tasks, and their state.>

   ## Next steps
   1. <Concrete next action, with the command to run where useful.>
   - **Tests to run:** ...
   - **Open questions:** ...
   - **Risks:** ...

   ## Resume prompt
   `<the one-line resume prompt from step 6>`
   ```

5. **Update `HANDOFF.md`** at the project root as an index:

   ```markdown
   # HANDOFF

   > Index of session handoffs, newest first. Read **Latest** before starting
   > work. Maintained by `/handoff`.

   ## Latest
   - [<Title> — YYYY-MM-DD HH:MM](docs/handoffs/<file>.md)

   ## History
   - [<older title> — YYYY-MM-DD HH:MM](docs/handoffs/<older file>.md)
   ```

   Move the previous "Latest" entry to the top of "History". If `HANDOFF.md`
   exists but isn't in this index format, first move its full content to
   `docs/handoffs/handoff-legacy-<YYYY-MM-DD>.md` (nothing gets lost), list
   that file in History, and tell the user you did so.

6. **Write the resume prompt.** One line, under ~300 characters, that a
   brand-new session can act on with no other context. It must contain the
   **absolute** project path, the handoff file path, and the first next step:

   `In <absolute project root>, read HANDOFF.md and docs/handoffs/<file>.md, then <first next step, concretely>.`

   Put it in the handoff's "Resume prompt" section.

7. **Never commit.** Handoff files stay local and untracked. Reply with the handoff
   path and a two-line summary, and end the reply with the resume prompt
   alone in a code block, as the very last thing, so it's easy to copy.
