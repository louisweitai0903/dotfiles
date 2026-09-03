# Database Migration Standards

When working with migrations:

- Always research and follow the latest best practices for the framework, ORM, and database.
- Review existing migration patterns before creating new migrations.
- Prefer backward-compatible migrations.
- Ensure migrations are reversible whenever possible.
- Validate migration ordering and dependencies.
- Run migration checks and validation tools.
- Verify application functionality after migrations are applied.
- Consider locking, downtime, and performance implications.
- Use zero-downtime migration strategies whenever possible.

Never:

- Drop columns without approval.
- Drop tables without approval.
- Rename critical columns without approval.
- Make destructive schema changes without explaining risks.
