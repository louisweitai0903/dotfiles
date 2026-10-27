# Project Documentation Standards

Documentation is mandatory for every project.

Required structure:

```text
project-root/
│
├── README.md
├── STATUS.md
├── PROGRESS.md
├── docs/
│   ├── architecture.md
│   ├── folder-structure.md
│   ├── setup.md
│   └── ...
```

## README.md

README.md must always be maintained and updated.

It should contain:

- Project overview
- Purpose and goals
- Features
- Technology stack
- Installation instructions
- Environment setup
- Configuration requirements
- Running the application
- Testing instructions
- Deployment instructions
- Known limitations
- Future improvements

Whenever functionality changes, verify whether the README requires updates.

## STATUS.md

STATUS.md represents the current state of the project.

Include:

- Current version
- Project health
- Completed features
- Features in progress
- Known issues
- Technical debt
- Blockers
- Upcoming milestones

Update STATUS.md whenever a task changes the project state.

## PROGRESS.md

PROGRESS.md acts as a development journal.

Every completed task should record:

- Date
- Task description
- Files modified
- Summary of implementation
- Validation performed
- Remaining concerns

This file should provide a clear history of development work.

## HANDOFF.md (optional)

Handoffs are optional and not a required file. Only write or read one
when the user asks (in Claude Code, `/handoff`). If a repo already has its
own handoff files, leave them as they are.

HANDOFF.md is the continuity document for future sessions. It should help the next agent quickly understand the current project state without re-discovering completed work.

Include:

- Failed attempts, including what was tried and why it did not work.
- A concise summary of STATUS.md, focused on current project health, blockers, and active work.
- A concise summary of PROGRESS.md, focused on the latest completed tasks and validation performed.
- Changes made during the current session, especially core functions, architecture, data flows, commands, and important files modified.
- Clear next steps, including recommended commands, tests, open questions, and risks.

Write one handoff per session at `docs/handoffs/handoff-<title>-YYYY-MM-DD-HHMM.md`
(in Claude Code, `/handoff <title>` does this). `HANDOFF.md` at the project
root is then an index: a **Latest** link to the newest handoff, followed by a
newest-first **History** list.
Each handoff ends with a one-line **resume prompt** (absolute project path,
handoff file, first next step) that can be pasted into a new session.

## Local-only files

Handoffs and daily task lists are personal session notes. They stay in the
project but are never committed:

- `/HANDOFF.md`
- `/docs/handoffs/`
- `/docs/tasks/` (see `daily-tasks.md`)

Before creating any of these in a git repo, make sure each path is listed
in `$(git rev-parse --git-common-dir)/info/exclude`, and add any that are
missing. This keeps them untracked without touching the repo's shared
`.gitignore`. Never stage or commit them. If the repo already tracks one of
them, leave it as it is: don't untrack, exclude or migrate it.

## docs/

Every project must contain a docs folder.

Documentation should cover:

- Architecture
- Folder structure
- Design decisions
- Database schema
- API documentation
- Authentication flow
- Deployment procedures
- Development workflow
- Third-party integrations

## Folder Documentation

Important folders should have documentation describing:

- Purpose
- Responsibilities
- Key files
- Dependencies
- Usage patterns

A new developer should be able to understand the structure of the project by reading the documentation.

## Documentation Maintenance

Documentation is part of the implementation.

Whenever code changes:

1. Review README.md.
2. Review STATUS.md.
3. Review PROGRESS.md.
4. Review docs/.
5. Update any outdated documentation.

A task is not complete until documentation is updated.
