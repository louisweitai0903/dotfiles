#!/usr/bin/env bash
# Symlinks AGENTS.md into every AI tool's global config location.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_FILE="$REPO_DIR/AGENTS.md"

link() {
  local target="$1"
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$target.bak.$(date +%s)"
    echo "Backed up existing $target"
  fi
  ln -sf "$AGENTS_FILE" "$target"
  echo "Linked $target -> $AGENTS_FILE"
}

link "$HOME/.claude/CLAUDE.md"

echo
echo "Global instructions linked for Claude Code."
echo "For GitHub Copilot (per-project only), run:"
echo "  $REPO_DIR/link-copilot.sh <path-to-project>"
