#!/usr/bin/env bash
# PreToolUse hook (Bash): blocks a `git commit` run by Claude Code unless a
# review file (docs/reviews/*.md) is part of that commit. The review file is
# produced by the /commit-review skill — see docs/feature-review.md.
#
# Reads the hook JSON on stdin. Allows by exiting 0 with no output; denies by
# printing a hookSpecificOutput "deny" decision. Every decision is logged to
# $COMMIT_REVIEW_GATE_LOG (default ~/.claude/logs/commit-review-gate.log).
# Tests: hooks/test-commit-review-gate.sh
set -uo pipefail

LOG_FILE="${COMMIT_REVIEW_GATE_LOG:-$HOME/.claude/logs/commit-review-gate.log}"
# docs/reviews/ at the repo root, or under a subproject (monorepos).
REVIEW_PATTERN='(^|/)docs/reviews/[^/]+\.md$'

log() {
  mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || return 0
  printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$*" >>"$LOG_FILE" 2>/dev/null || true
}

decided=0

allow() {
  decided=1
  log "ALLOW $*"
  exit 0
}

deny() {
  local repo="$1" reason="$2"
  decided=1
  log "DENY repo=$repo reason=$reason"
  jq -n --arg r "$reason" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

if ! command -v jq >/dev/null 2>&1; then
  # Can't parse the hook input; fail open rather than block every Bash call.
  log "ALLOW jq-missing (gate inactive)"
  exit 0
fi

input="$(cat)"
cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"

# Drop heredoc bodies (a commit message written as "$(cat <<'EOF' … EOF)" can
# contain anything, including unbalanced quotes), then replace quoted strings
# (messages, echo/grep arguments) with Q, so their text can't pass for git
# commands or flags. Newlines become ';' so each line is its own segment.
bare="$(awk '
  term != "" { t = $0; sub(/^\t+/, "", t); if (t == term) term = ""; next }
  { print }
  match($0, /(^|[^<])<<-?[ \t]*["\047]?[A-Za-z_][A-Za-z0-9_]*["\047]?/) {
    h = substr($0, RSTART, RLENGTH)
    sub(/^[^<]?<<-?[ \t]*["\047]?/, "", h); sub(/["\047]$/, "", h)
    term = h
  }' <<<"$cmd" | tr '\n' ';' | sed -E "s/\"([^\"\\\\]|\\\\.)*\"/Q/g; s/'[^']*'/Q/g")"

# Match `[/path/]git [global opts] commit`, but not `git commit-tree` or
# `git log --grep commit`.
git_re='(^|[^[:alnum:]_.-])(/[^[:space:]]*/)?git'
git_commit_re="${git_re}([[:space:]]+(-C|-c|--git-dir|--work-tree|--namespace)[[:space:]]+[^[:space:]]+|[[:space:]]+--?[[:alnum:]][^[:space:]]*)*[[:space:]]+commit([[:space:]]|\$|[;&|)])"
if ! grep -Eq "$git_commit_re" <<<"$bare"; then
  exit 0 # not a commit; don't log every Bash call
fi
log "CHECK cwd=$cwd cmd=$(tr '\n' ' ' <<<"$cmd")"

# From here on it's a commit: if the script dies without deciding (a bug, an
# unexpected input), block rather than let the commit through. Exit 2 is the
# blocking code; any other non-zero exit would let the tool call run.
on_exit() {
  if [ "$decided" = 0 ]; then
    log "DENY internal-error cmd=$(tr '\n' ' ' <<<"$cmd")"
    echo "commit-review gate hit an internal error and blocked this commit. Stage files separately, run /commit-review, and use a plain \`git commit\`." >&2
    exit 2
  fi
}
trap on_exit EXIT

# Resolve the repo: `git -C <path>` on the commit invocation itself wins over
# the session cwd, after any `cd <path>` earlier in the command. Paths are read
# from $bare, so text inside quoted messages is ignored. Anything that can't be
# resolved unambiguously (quoted or variable paths) is denied, not guessed.
before_commit="$(sed -E "s#${git_commit_re}.*##" <<<"$bare")"
invocation="$(grep -Eo "$git_commit_re" <<<"$bare" | head -n1)"
unresolvable="The review gate can't tell which repo this commit targets (quoted or variable path). Run the commit as its own command with a literal path, e.g. \`git -C /abs/path commit\`."

# resolve <path> <base>: print <path> as an absolute path.
resolve() {
  local p="${1/#\~/$HOME}"
  case "$p" in
    /*) echo "$p" ;;
    *) echo "$2/$p" ;;
  esac
}

dir="$cwd"
explicit=0
cd_path="$(sed -nE 's/.*(^|[;&|(])[[:space:]]*cd[[:space:]]+([^[:space:];&|)]+).*/\2/p' <<<"$before_commit")"
if [ -n "$cd_path" ]; then
  case "$cd_path" in Q | */Q | *'$'*) deny "?" "$unresolvable" ;; esac
  dir="$(resolve "$cd_path" "$cwd")"
  explicit=1
fi

c_path="$(sed -nE 's/.*[[:space:]]-C[[:space:]]+([^[:space:]]+).*/\1/p' <<<"$invocation")"
if [ "$c_path" = Q ]; then
  # Only safe when exactly one quoted `git -C` exists in the whole command.
  quoted_c="$(grep -Eo "git[[:space:]]+-C[[:space:]]+(\"[^\"]+\"|'[^']+')" <<<"$cmd")"
  [ "$(grep -c . <<<"$quoted_c")" -eq 1 ] || deny "?" "$unresolvable"
  c_path="$(sed -E "s/^git[[:space:]]+-C[[:space:]]+[\"']//; s/[\"']$//" <<<"$quoted_c")"
fi
if [ -n "$c_path" ]; then
  dir="$(resolve "$c_path" "$dir")"
  explicit=1
fi

if [ "$explicit" = 1 ]; then
  repo="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || deny "?" "$unresolvable"
else
  repo="$(git -C "${dir:-.}" rev-parse --show-toplevel 2>/dev/null)" || allow "not-a-repo dir=$dir"
fi

# Staging in the same command (`git add x && git commit`) runs after this hook,
# so the index can't be checked yet — require staging as a separate step.
if grep -Eq "${git_re}([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+(add|rm|mv)([[:space:]]|\$)" <<<"$before_commit"; then
  deny "$repo" "Stage files in a separate command before committing, so the review gate can see what will be committed. Then run /commit-review if no review file is staged, and commit with a plain \`git commit\`."
fi

# Parse the commit's own arguments, up to the next command separator or redirect.
after_commit="$(sed -E "s#^.*${git_commit_re}##" <<<"$bare")"
after_commit="${after_commit%%[;&|]*}"
read -ra args <<<"$after_commit"
all=0 amend=0 allow_empty=0 pathspec="" skip=0
# ${args[@]+...}: macOS bash 3.2 treats an empty array as unbound under set -u.
for arg in ${args[@]+"${args[@]}"}; do
  if [ "$skip" = 1 ]; then
    skip=0
    continue
  fi
  [[ "$arg" =~ ^-[[:alpha:]]*a[[:alpha:]]*$ || "$arg" == --all ]] && all=1
  [ "$arg" = --amend ] && amend=1
  [ "$arg" = --allow-empty ] && allow_empty=1
  case "$arg" in
    \<* | \>* | [0-9]\>*) break ;;
    -- | -o | --only | -i | --include | --pathspec-from-file*)
      pathspec="$arg"
      break
      ;;
    --message | --file | --reuse-message | --reedit-message | --template | --author | --date | --cleanup | --fixup | --squash | --trailer)
      skip=1
      ;;
    -*)
      # -m/-F/-C/-c/-t (also combined, e.g. -am) take the next word as a value
      [[ "$arg" =~ ^-[[:alpha:]]*[mFCct]$ ]] && skip=1
      ;;
    *)
      pathspec="$arg"
      break
      ;;
  esac
done

# A pathspec commit commits only the named paths, ignoring the rest of the
# index — a staged review file would be silently left out.
if [ -n "$pathspec" ]; then
  deny "$repo" "Commits that name paths (\`git commit <paths>\`, -o/--only, -i, --pathspec-from-file) aren't allowed by the review gate, because they can leave the staged review file out of the commit. Stage the files, run /commit-review, then run a plain \`git commit\`."
fi

# Files that will land in the commit: staged ones, plus tracked modified files for -a/--all.
# Deletions count as changes but never as a review file.
changes="$(git -c core.quotePath=false -C "$repo" diff --cached --name-status --diff-filter=ACMRD)"
if [ "$all" = 1 ]; then
  changes="$changes"$'\n'"$(git -c core.quotePath=false -C "$repo" diff --name-status --diff-filter=ACMRD)"
fi
files="$(awk -F'\t' '$1 != "D" && NF > 1 { print $NF }' <<<"$changes" | sort -u)"

if [ -z "$(sed '/^$/d' <<<"$changes")" ]; then
  # Only a message-only amend or an explicit empty commit is legitimate here;
  # anything else would commit nothing.
  if [ "$amend" = 1 ] || [ "$allow_empty" = 1 ]; then
    allow "repo=$repo nothing-staged (amend/allow-empty)"
  fi
  deny "$repo" "Nothing is staged. Stage the files for this change first, run /commit-review, then commit."
fi

if grep -Eq "$REVIEW_PATTERN" <<<"$files"; then
  allow "repo=$repo review=$(grep -E "$REVIEW_PATTERN" <<<"$files" | tr '\n' ' ')"
fi

# Amending a commit that already carries its review file keeps that file.
if [ "$amend" = 1 ] && git -c core.quotePath=false -C "$repo" diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null | grep -Eq "$REVIEW_PATTERN"; then
  allow "repo=$repo amend-of-reviewed-commit"
fi

deny "$repo" "No review file is staged for this commit. Run /commit-review first: it reviews the staged changes in a fresh subagent and stages docs/reviews/YYYY-MM-DD-<slug>.md. Then commit again, including that file."
