# Implementation Standards

When writing code:

- Follow SOLID principles when appropriate.
- Prefer readability over cleverness.
- Avoid unnecessary abstractions.
- Avoid duplication.
- Handle edge cases.
- Add meaningful error handling.
- Follow existing project conventions.
- Keep functions small and focused.

## Shared logic

If a function or module is used across multiple places (multiple modules,
services, or repos), extract it into its own reusable module, package,
function, or microservice — callable globally — rather than copying or
rewriting the logic at each call site. Apply this once real reuse exists;
don't pre-extract for hypothetical future callers (see "avoid unnecessary
abstractions" above).

## Full-stack applications

When asked to create a full-stack application, containerize it with Docker
(a `Dockerfile` per service, plus `docker-compose` for multi-service local
orchestration) rather than relying on ad hoc local setup.
