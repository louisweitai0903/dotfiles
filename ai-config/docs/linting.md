# Linting and Static Analysis

For every project:

1. Identify the standard linter.
2. Run linting after changes.
3. Fix syntax issues.
4. Fix import issues.
5. Fix lint violations introduced by the task.
6. Run type checking where applicable.

Examples:

- JavaScript/TypeScript: ESLint
- React/Next.js: ESLint + TypeScript
- Python: Ruff, Black, MyPy
- Go: gofmt, golangci-lint
- Rust: cargo fmt, cargo clippy
- Java: Checkstyle, SpotBugs
- C#: dotnet format

Do not leave linting issues introduced by your changes.
