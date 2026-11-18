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

## Design for failure

Build things to account for failure, not to totally prevent it. Assume
dependencies, networks, disks and inputs will fail at some point, and make
the failure safe, visible and recoverable rather than chasing a design
where it can never happen:

- Fail safe: a failure leaves data consistent and never half-written
  (transactions, idempotent operations, atomic writes).
- Fail visible: surface errors with enough context to act on; never
  swallow them silently.
- Recover: use timeouts, bounded retries with backoff, and graceful
  degradation so one failing part doesn't take down the rest.
- Make the recovery path real: rollback, replay or restart should be
  possible and, where practical, tested.
- Large production traffic: put slow or bursty work behind Redis or a
  message queue instead of handling it inline. When Redis or the queue
  is unavailable, retry with bounded backoff, then fail visibly (or
  spool the work for replay); never drop it silently.
