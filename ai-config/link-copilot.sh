#!/usr/bin/env bash
# Symlinks AGENTS.md as GitHub Copilot's per-project instructions file.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_FILE="$REPO_DIR/AGENTS.md"
TARGET_DIR="${1:?Usage: link-copilot.sh <path-to-project>}"

mkdir -p "$TARGET_DIR/.github"
TARGET="$TARGET_DIR/.github/copilot-instructions.md"

if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
  mv "$TARGET" "$TARGET.bak.$(date +%s)"
  echo "Backed up existing $TARGET"
fi

ln -sf "$AGENTS_FILE" "$TARGET"
echo "Linked $TARGET -> $AGENTS_FILE"
