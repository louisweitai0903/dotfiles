#!/usr/bin/env bash
# Concatenates docs/*.md, in ORDER below, into AGENTS.md — the single file
# symlinked out to every agent's global config. Edit docs/*.md, not
# AGENTS.md directly, then run this.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$REPO_DIR/docs"
OUT="$REPO_DIR/AGENTS.md"

ORDER=(
  role.md
  safety.md
  before-starting.md
  execution-plan.md
  scope-control.md
  implementation-standards.md
  frontend-references.md
  database-migrations.md
  dependencies.md
  documentation-standards.md
  feature-review.md
  commit-messages.md
  code-review.md
  security-review.md
  debugging.md
  linting.md
  testing.md
  validation.md
  communication.md
  decision-making.md
  definition-of-done.md
)

{
  echo "# AGENTS.md"
  echo
  echo "> Generated from ai-config/docs/*.md by build.sh — edit those files, not this one."
  for f in "${ORDER[@]}"; do
    echo
    echo "---"
    echo
    cat "$DOCS_DIR/$f"
  done
} > "$OUT"

echo "Built $OUT from ${#ORDER[@]} docs."
