# Security Review

- **Input validation** — validate and sanitize at every trust boundary: user
  input, external API responses, file uploads, query params.
- **Injection** — check for SQL, command, template, and XSS injection
  wherever user-controlled data reaches a query, shell, template, or DOM.
- **AuthN/AuthZ** — every new endpoint or action checks the right
  authentication and authorization; watch for confused-deputy and IDOR
  patterns (one user reaching another user's data via a guessable ID).
- **Secrets** — never hardcode credentials, keys, or tokens; never log them;
  use environment variables or a secrets manager.
- **Dependencies** — check new packages for known CVEs and maintenance
  status before adding them (see `dependencies.md`).
- **Data exposure** — API responses return only the fields needed; don't
  leak stack traces or internal error detail to clients.
- **Cryptography** — don't roll your own; use vetted libraries and current
  standards.
- **File/network operations** — validate file paths against traversal and
  outbound URLs against SSRF.

If a finding requires a product or security-posture decision rather than an
obvious fix, flag it and ask rather than resolving it unilaterally.
