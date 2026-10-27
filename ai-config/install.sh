#!/usr/bin/env bash
# Symlinks AGENTS.md, skills, agents and hooks into Claude Code's global
# config, and registers the commit-review gate hook in settings.json.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_FILE="$REPO_DIR/AGENTS.md"
CLAUDE_DIR="$HOME/.claude"
GATE_HOOK="$CLAUDE_DIR/hooks/commit-review-gate.sh"

BACKUP_DIR="$CLAUDE_DIR/backups"

# link <source> <target>: move a real file/dir at <target> to $BACKUP_DIR
# (outside skills/ and agents/, so Claude Code doesn't load backups as
# duplicates), then symlink. -n so re-linking a directory replaces the link
# instead of nesting inside it.
link() {
  local source="$1" target="$2"
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mkdir -p "$BACKUP_DIR"
    local backup
    backup="$BACKUP_DIR/$(basename "$target").bak.$(date +%s)"
    mv "$target" "$backup"
    echo "Backed up existing $target to $backup"
  fi
  ln -sfn "$source" "$target"
  echo "Linked $target -> $source"
}

# Adds the commit-review gate as a PreToolUse hook on Bash, once.
register_gate_hook() {
  local settings="$CLAUDE_DIR/settings.json"
  local hook_cmd="bash $GATE_HOOK"
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found: skipped registering the commit-review hook in $settings" >&2
    return
  fi
  [ -f "$settings" ] || echo '{}' >"$settings"
  if jq -e --arg c "$hook_cmd" '[.hooks.PreToolUse[]?.hooks[]?.command] | index($c)' "$settings" >/dev/null; then
    echo "Commit-review hook already registered in $settings"
    return
  fi
  cp "$settings" "$settings.bak.$(date +%s)"
  local tmp
  tmp="$(mktemp)"
  if ! jq --arg c "$hook_cmd" \
    '.hooks.PreToolUse = ((.hooks.PreToolUse // []) + [{matcher: "Bash", hooks: [{type: "command", command: $c}]}])' \
    "$settings" >"$tmp"; then
    rm -f "$tmp"
    echo "Could not update $settings (invalid JSON?) — hook not registered" >&2
    return 1
  fi
  # Write in place (not mv) so a symlinked settings.json stays a symlink.
  cat "$tmp" >"$settings"
  rm -f "$tmp"
  echo "Registered commit-review hook in $settings (backup saved alongside)"
}

link "$AGENTS_FILE" "$CLAUDE_DIR/CLAUDE.md"

for skill in "$REPO_DIR"/skills/*/; do
  [ -f "$skill/SKILL.md" ] || continue
  link "${skill%/}" "$CLAUDE_DIR/skills/$(basename "$skill")"
done

for agent in "$REPO_DIR"/agents/*.md; do
  [ -f "$agent" ] || continue
  link "$agent" "$CLAUDE_DIR/agents/$(basename "$agent")"
done

link "$REPO_DIR/hooks/commit-review-gate.sh" "$GATE_HOOK"
register_gate_hook

echo
echo "Global instructions, skills, agents and hooks linked for Claude Code."
echo "Restart Claude Code sessions to pick up new skills, agents and hooks."
echo "For GitHub Copilot (per-project only), run:"
echo "  $REPO_DIR/link-copilot.sh <path-to-project>"
