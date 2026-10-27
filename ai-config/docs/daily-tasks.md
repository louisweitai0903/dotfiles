# Daily Task List

Each project keeps one task list per day at
`docs/tasks/YYYY-MM-DD.md` under the project root (local date, from
`date +%F`). The project root is `git rev-parse --show-toplevel`, or the
current directory if it isn't a git repo. Task files are personal notes:
they stay local and are never committed.

Only the top-level session follows this section. Skip it when running as
a subagent or when spawned by another agent.

## At the start of every session

1. Get today's date with `date +%F` and read `docs/tasks/<today>.md` in
   the current project. If the session isn't in a project (e.g. the home
   directory), skip this section unless the user asks for a task list.
2. **If the file exists:** its open items are today's objectives. Briefly
   name the open items, then work on what the user asks for. If the user's
   request is something else, do that instead. Don't steer them back to the
   list. If that work isn't on the list, add it as a new item.
3. **If the file doesn't exist:** don't hold up the user's first message.
   If it's a concrete task, start the work and create the file with that
   task as the first item. If it's a question, answer it. Either way, ask
   in the same reply what else they're working on today in this project.
   If the first message is only a greeting, just ask.
4. If the most recent earlier file in `docs/tasks/` has unfinished items,
   offer to carry them over. Don't copy them without asking.

## Keeping task files out of git

Task files are local-only. Before creating `docs/tasks/`, follow the
"Local-only files" rules in `documentation-standards.md`.

## File format

```markdown
# Tasks — YYYY-MM-DD

## Summary
<2–4 sentences on what got done today. Rewrite it whenever an item is
finished. "Nothing finished yet." until then.>

## Tasks
- [ ] <short description>
- [x] <short description> — done HH:MM
  - Changes: <what changed and why, key files, commit short SHAs>
```

## Marking an item done

An item is done when its work meets the Definition of Done, which includes
being committed if it involves code. So mark it after the work's commit,
when the SHAs exist:

1. Tick it (`- [x]`) and append `— done HH:MM`.
2. Add a `Changes:` line under it with a one-line summary of what changed,
   the key files, and the commit short SHAs.
3. Rewrite the `## Summary` section to cover everything done so far today.

## Rules

- Re-read the file right before every edit. Other sessions may have
  changed it. Only change the items this session is working on.
- Never delete items. If one is dropped, mark it `- [-]` and add a reason.
- Never record secrets, credentials, or customer PII in the file.
- `/handoff` links to today's task file and summarises its status.
