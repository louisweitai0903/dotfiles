#!/usr/bin/env bash
# PreToolUse hook (Bash) enforcing the branch + draft PR workflow (see
# docs/commit-messages.md and docs/feature-review.md):
# - `git commit` is denied on a protected branch (PROTECTED_RE). On any other
#   branch it's allowed; commits there need no review of their own.
# - `gh pr create` is denied unless it's a draft for the current branch
#   (no --head/--repo) and the branch, compared with its base, adds a
#   committed review file (docs/reviews/*.md), produced by the
#   /commit-review skill. Docs-only branches (every changed path matches
#   DOC_PATTERN) are exempt.
#
# Reads the hook JSON on stdin. Allows by exiting 0 with no output; denies by
# printing a hookSpecificOutput "deny" decision. Every decision is logged to
# $COMMIT_REVIEW_GATE_LOG (default ~/.claude/logs/commit-review-gate.log).
# Tests: hooks/test-commit-review-gate.sh
set -uo pipefail

LOG_FILE="${COMMIT_REVIEW_GATE_LOG:-$HOME/.claude/logs/commit-review-gate.log}"
PROTECTED_RE='^(main|master|dev|staging)$'
# docs/reviews/ at the repo root, or under a subproject (monorepos).
REVIEW_PATTERN='(^|/)docs/reviews/[^/]+\.md$'
# Documentation files (matched case-insensitively). A branch touching only
# these needs no review. LICENSE-style names match only without an extension
# (CHANGELOG.md etc. are covered by the extension list), so code such as
# changes.py or Notice.tsx still needs review.
DOC_PATTERN='(\.(md|mdx|markdown|rst|txt|adoc)|(^|/)(licen[cs]e|changelog|changes|authors|contributors|notice|copying))$'

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
# `git log --grep commit`; and `[/path/]gh [global opts] pr create`.
git_re='(^|[^[:alnum:]_.-])(/[^[:space:]]*/)?git'
git_commit_re="${git_re}([[:space:]]+(-C|-c|--git-dir|--work-tree|--namespace)[[:space:]]+[^[:space:]]+|[[:space:]]+--?[[:alnum:]][^[:space:]]*)*[[:space:]]+commit([[:space:]]|\$|[;&|)])"
pr_create_re="(^|[^[:alnum:]_.-])(/[^[:space:]]*/)?gh([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+pr[[:space:]]+create([[:space:]]|\$|[;&|)])"

is_commit=0 is_pr=0
grep -Eq "$git_commit_re" <<<"$bare" && is_commit=1
grep -Eq "$pr_create_re" <<<"$bare" && is_pr=1
if [ "$is_commit" = 0 ] && [ "$is_pr" = 0 ]; then
  exit 0 # neither a commit nor a PR; don't log every Bash call
fi
log "CHECK cwd=$cwd cmd=$(tr '\n' ' ' <<<"$cmd")"

# From here on it's gated: if the script dies without deciding (a bug, an
# unexpected input), block rather than let it through. Exit 2 is the blocking
# code; any other non-zero exit would let the tool call run.
on_exit() {
  if [ "$decided" = 0 ]; then
    log "DENY internal-error cmd=$(tr '\n' ' ' <<<"$cmd")"
    echo "The commit/PR gate hit an internal error and blocked this command. Run the commit or \`gh pr create\` as its own plain command." >&2
    exit 2
  fi
}
trap on_exit EXIT

if [ "$is_commit" = 1 ] && [ "$is_pr" = 1 ]; then
  deny "?" "Commit, push, and run \`gh pr create\` as separate commands, so the gate can check the branch as it will be when the PR opens."
fi

if [ "$is_commit" = 1 ]; then
  invocation_re="$git_commit_re"
else
  invocation_re="$pr_create_re"
fi

# Resolve the repo: `git -C <path>` on the commit invocation itself wins over
# the session cwd, after any `cd <path>` earlier in the command. Paths are read
# from $bare, so text inside quoted messages is ignored. Anything that can't be
# resolved unambiguously (quoted or variable paths) is denied, not guessed.
before="$(sed -E "s#${invocation_re}.*##" <<<"$bare")"
invocation="$(grep -Eo "$invocation_re" <<<"$bare" | head -n1)"
unresolvable="The gate can't tell which repo this command targets (quoted or variable path). Run it as its own command with a literal path, e.g. \`git -C /abs/path commit\` or \`cd /abs/path && gh pr create …\`."

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
cd_path="$(sed -nE 's/.*(^|[;&|(])[[:space:]]*cd[[:space:]]+([^[:space:];&|)]+).*/\2/p' <<<"$before")"
if [ -n "$cd_path" ]; then
  case "$cd_path" in Q | */Q | *'$'*) deny "?" "$unresolvable" ;; esac
  dir="$(resolve "$cd_path" "$cwd")"
  explicit=1
fi

if [ "$is_commit" = 1 ]; then
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
fi

if [ "$explicit" = 1 ]; then
  repo="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || deny "?" "$unresolvable"
else
  repo="$(git -C "${dir:-.}" rev-parse --show-toplevel 2>/dev/null)" || allow "not-a-repo dir=$dir"
fi

# Commits: allowed anywhere except a protected branch.
if [ "$is_commit" = 1 ]; then
  # A branch switch earlier in the same command runs after this hook, so the
  # branch it lands on can't be checked yet.
  if grep -Eq "${git_re}([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+(switch|checkout)([[:space:]]|\$)" <<<"$before"; then
    deny "$repo" "Switch or create the branch in a separate command, then commit, so the gate can see which branch the commit lands on."
  fi
  branch="$(git -C "$repo" symbolic-ref --short -q HEAD)" || allow "repo=$repo detached-head"
  if grep -Eq "$PROTECTED_RE" <<<"$branch"; then
    if ! git -C "$repo" rev-parse -q --verify HEAD >/dev/null; then
      allow "repo=$repo branch=$branch initial-commit"
    fi
    deny "$repo" "Commits on \`$branch\` aren't allowed. Create a feature branch first, as its own command (\`git switch -c <type>/<slug>\`, e.g. \`feat/invoice-export\`), then commit there. The review runs once, before the draft PR."
  fi
  allow "repo=$repo branch=$branch"
fi

# PRs: the branch must carry a committed review file, compared with its base.
# A global `gh -R/--repo` (before `pr`) targets a repo the gate can't see.
if grep -Eq '[[:space:]](-R|--repo)' <<<"$(sed -E 's/[[:space:]]+pr[[:space:]]+create.*//' <<<"$invocation")"; then
  deny "$repo" "\`gh pr create\` with \`--head\` or \`--repo\` isn't allowed: the gate can only check the current branch of this repo. Switch to the branch and run \`gh pr create --draft\` from it, without those flags."
fi
after="$(sed -E "s#^.*${pr_create_re}##" <<<"$bare")"
after="${after%%[;&|]*}"
read -ra args <<<"$after"
base="" skip=0 draft=0
# ${args[@]+...}: macOS bash 3.2 treats an empty array as unbound under set -u.
for arg in ${args[@]+"${args[@]}"}; do
  if [ "$skip" = 1 ]; then
    base="$arg"
    skip=0
    continue
  fi
  case "$arg" in
    --base | -B) skip=1 ;;
    --base=*) base="${arg#--base=}" ;;
    -B?*) base="${arg#-B}" ;;
    --draft | -d | --draft=true) draft=1 ;;
    --draft=*) draft=0 ;;
    # The gate only inspects the current branch of the local repo, so a PR
    # for another branch or repo can't be checked. -H*/-R* also cover the
    # attached forms (-Hbranch, -Rowner/repo).
    --head | --head=* | -H* | --repo | --repo=* | -R*)
      deny "$repo" "\`gh pr create\` with \`--head\` or \`--repo\` isn't allowed: the gate can only check the current branch of this repo. Switch to the branch and run \`gh pr create --draft\` from it, without those flags."
      ;;
    \<* | \>* | [0-9]\>*) break ;;
  esac
done
if [ "$draft" = 0 ]; then
  deny "$repo" "PRs must be opened as drafts. Add \`--draft\`."
fi
if [ "$base" = Q ] || [[ "$base" == *'$'* ]]; then
  deny "$repo" "Pass \`--base\` as a literal, unquoted branch name (e.g. \`--base main\`), so the gate can compare the branch with it."
fi

if [ -z "$base" ]; then
  # gh defaults to the repo's default branch: origin/HEAD, else main/master.
  base_ref="$(git -C "$repo" symbolic-ref --short -q refs/remotes/origin/HEAD)"
  if [ -z "$base_ref" ]; then
    for b in origin/main origin/master main master; do
      if git -C "$repo" rev-parse -q --verify "$b^{commit}" >/dev/null; then
        base_ref="$b"
        break
      fi
    done
  fi
  [ -n "$base_ref" ] || deny "$repo" "Can't find the default branch to compare with. Pass \`--base <branch>\` explicitly."
elif git -C "$repo" rev-parse -q --verify "refs/remotes/origin/$base^{commit}" >/dev/null; then
  base_ref="origin/$base"
elif git -C "$repo" rev-parse -q --verify "refs/heads/$base^{commit}" >/dev/null; then
  base_ref="$base"
else
  deny "$repo" "Base branch \`$base\` doesn't exist locally or on origin. Fetch it or fix \`--base\`."
fi

changes="$(git -c core.quotePath=false -C "$repo" diff --name-status --diff-filter=ACMRD "$base_ref...HEAD" 2>/dev/null)" ||
  deny "$repo" "Can't compare this branch with \`$base_ref\` (no common history?). Pass the correct \`--base\`."

if [ -z "$changes" ]; then
  allow "repo=$repo base=$base_ref no-changes"
fi

# Docs-only branches are exempt. Every path counts, including deletions and
# both sides of a rename.
paths="$(awk -F'\t' 'NF > 1 { for (i = 2; i <= NF; i++) print $i }' <<<"$changes" | sort -u)"
if ! grep -Eiv "$DOC_PATTERN" <<<"$paths" | grep -q .; then
  allow "repo=$repo base=$base_ref docs-only"
fi

# Only a review file this branch adds counts. Editing or deleting an older
# one already on the base doesn't review this branch.
files="$(awk -F'\t' '$1 == "A" && NF > 1 { print $NF }' <<<"$changes" | sort -u)"
if grep -Eq "$REVIEW_PATTERN" <<<"$files"; then
  allow "repo=$repo base=$base_ref review=$(grep -E "$REVIEW_PATTERN" <<<"$files" | tr '\n' ' ')"
fi

deny "$repo" "No review file is committed on this branch (compared with \`$base_ref\`). Run /commit-review: it reviews the whole branch in a fresh subagent and writes docs/reviews/YYYY-MM-DD-<slug>.md. Commit that file, push, then run \`gh pr create --draft\` again."
