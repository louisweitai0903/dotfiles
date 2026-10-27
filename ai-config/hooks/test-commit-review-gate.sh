#!/usr/bin/env bash
# Tests for commit-review-gate.sh: feeds hook JSON for each scenario against
# throwaway git repos and checks the allow/deny decision. Exits non-zero on
# any failure. Usage: ./hooks/test-commit-review-gate.sh
set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commit-review-gate.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export COMMIT_REVIEW_GATE_LOG="$TMP/gate.log"
R="$TMP/repo"
OUT="$TMP/notrepo"
U="$TMP/unborn"
ORIGIN="$TMP/origin.git"
mkdir -p "$R" "$OUT" "$U"
failures=0

# check <description> <cwd> <command> <allow|deny>
check() {
  local got=allow out
  out="$(jq -n --arg c "$3" --arg d "$2" '{tool_input: {command: $c}, cwd: $d}' | bash "$HOOK")"
  grep -q '"deny"' <<<"$out" && got=deny
  if [ "$got" = "$4" ]; then
    printf 'PASS  %s\n' "$1"
  else
    printf 'FAIL  %s (expected %s, got %s)\n' "$1" "$4" "$got"
    failures=$((failures + 1))
  fi
}

g() { git -C "$R" "$@"; }

g init -q && g symbolic-ref HEAD refs/heads/main
g config user.email test@example.com && g config user.name test
echo a >"$R/app.py" && g add . && g commit -qm init
git init -q --bare "$ORIGIN" && g remote add origin "$ORIGIN" && g push -q origin main && g remote set-head origin main

# Neither a commit nor a PR
check "non-commit command" "$R" "ls -la" allow
check "git add alone" "$R" "git add app.py" allow
check "git commit-tree" "$R" "git commit-tree abc" allow
check "git log --grep commit" "$R" "git log --grep commit" allow
check "echo mentioning git commit" "$R" 'echo "run git commit later"' allow
check "grep for git commit -m" "$R" "grep -rn 'git commit -m' docs" allow
check "gh pr list" "$R" "gh pr list" allow
check "echo mentioning gh pr create" "$R" 'echo "then gh pr create"' allow
check "outside any repo" "$OUT" "git commit -m x" allow

# Commits on protected branches are denied
echo b >>"$R/app.py" && g add app.py
check "commit on main" "$R" "git commit -m x" deny
check "plain git commit on main" "$R" "git commit" deny
check "-C commit on main from outside" "$OUT" "git -C $R commit -m x" deny
check "-C quoted path on main" "$OUT" "git -C '$R' commit -m x" deny
check "cd && commit on main" "$OUT" "cd $R && git commit -m x" deny
check "git -c option on main" "$R" "git -c core.editor=true commit -m x" deny
check "/usr/bin/git commit on main" "$R" "/usr/bin/git commit -m x" deny
check "--git-dir X commit on main" "$R" "git --git-dir .git commit -m x" deny
check "amend on main" "$R" "git commit --amend --no-edit" deny
check "docs-only commit on main" "$R" "git commit -m 'docs only'" deny
check "-C with a variable path" "$OUT" 'git -C "$REPO" commit -m x' deny
check "cd variable && commit" "$OUT" 'cd $REPO && git commit -m x' deny
check "cd quoted path && commit" "$OUT" "cd '$R' && git commit -m x" deny
check "cd <non-repo> && commit" "$R" "cd $OUT && git commit -m x" deny
check "two quoted -C paths (ambiguous)" "$OUT" "git -C '$OUT' status && git -C '$R' commit -m x" deny
for b in master dev staging; do
  g switch -q -c "$b"
  check "commit on $b" "$R" "git commit -m x" deny
  g switch -q main && g branch -q -D "$b"
done

# Initial commit in an unborn repo is allowed
git -C "$U" init -q && git -C "$U" symbolic-ref HEAD refs/heads/main && echo a >"$U/a.py" && git -C "$U" add .
check "initial commit on unborn main" "$U" "git commit -m init" allow

# Switching branch in the same command can't be checked
check "switch -c && commit" "$R" "git switch -c feat/y && git commit -m x" deny
check "checkout && commit" "$R" "git checkout -b feat/y && git commit -m x" deny

# Commits on feature branches are allowed, with no review
g switch -q -c feat/x
check "commit on feature branch" "$R" "git commit -m x" allow
check "plain commit on feature branch" "$R" "git commit" allow
check "-am on feature branch" "$R" "git commit -am x" allow
check "pathspec on feature branch" "$R" "git commit -m x app.py" allow
check "amend on feature branch" "$R" "git commit --amend --no-edit" allow
check "add && commit on feature branch" "$R" "git add app.py && git commit -m x" allow
check "-C quoted path on feature branch" "$OUT" "git -C '$R' commit -m x" allow
check "cd <repo> && commit on feature branch" "$OUT" "cd $R && git commit -m x" allow
check "message mentions git switch" "$R" "git commit -m 'feat: explain why git switch runs first'" allow
check "heredoc message mentions git checkout" "$R" "$(printf 'git commit -m "$(cat <<%sEOF%s\nfeat(x): y\n\nNever chain git checkout with commit.\nEOF\n)"' "'" "'")" allow
check "unquoted heredoc message" "$R" "$(printf 'git commit -F - <<EOF\nfeat(x): y\nEOF')" allow
check "escaped quotes in -m" "$R" 'git commit -m "say \"hi\""' allow
g switch -q -c main-fix
check "branch named like main-fix" "$R" "git commit -m x" allow
g switch -q feat/x && g branch -q -D main-fix
g commit -qm "code change"

# Detached HEAD is allowed
g switch -q --detach
check "commit on detached HEAD" "$R" "git commit -m x" allow
g switch -q feat/x

# PRs need a committed review file on the branch
check "PR, no review" "$R" "gh pr create --draft --title x" deny
check "PR, no review, --base main" "$R" "gh pr create --draft --base main" deny
check "PR, no review, --base=main" "$R" "gh pr create --draft --base=main" deny
check "PR, no review, -B main" "$R" "gh pr create -d -B main" deny
check "/usr/bin/gh pr create, no review" "$R" "/usr/bin/gh pr create --draft" deny
check "PR, quoted --base" "$R" "gh pr create --draft --base 'main'" deny
check "PR, unknown --base" "$R" "gh pr create --draft --base nope" deny
check "commit && PR in one command" "$R" "git commit -m x && gh pr create --draft" deny
mkdir -p "$R/docs/reviews" && echo r >"$R/docs/reviews/2026-01-01-x.md" && g add docs
check "PR, review staged but not committed" "$R" "gh pr create --draft" deny
g commit -qm "review"
check "PR, review committed" "$R" "gh pr create --draft --title x" allow
check "PR, review committed, --base main" "$R" "gh pr create --draft --base main" allow
check "cd <repo> && PR, review committed" "$OUT" "cd $R && gh pr create --draft" allow
check "PR body mentions git commit" "$R" 'gh pr create --draft --body "run git commit first"' allow
check "PR outside any repo" "$OUT" "gh pr create --draft" allow
g remote set-head origin -d
check "PR without origin/HEAD falls back to origin/main" "$R" "gh pr create --draft" allow
g remote set-head origin main

# A branch that deletes a review file and changes code is not reviewed
g push -q origin feat/x:main && g switch -q -c feat/del
g rm -q docs/reviews/2026-01-01-x.md && echo c >>"$R/app.py" && g add app.py && g commit -qm "del review"
check "PR, deleted review doesn't count" "$R" "gh pr create --draft" deny

# Subproject review location
mkdir -p "$R/pkg/a/docs/reviews" && echo r >"$R/pkg/a/docs/reviews/2026-01-01-y.md" && g add pkg && g commit -qm sub
check "PR, subproject review" "$R" "gh pr create --draft" allow

# Docs-only branches need no review
g switch -q main && g reset -q --hard origin/main && g switch -q -c docs/readme
echo n >"$R/README.md" && echo n >"$R/LICENSE" && g add . && g commit -qm docs
check "PR, docs-only branch" "$R" "gh pr create --draft" allow
echo n >"$R/run.sh" && g add run.sh && g commit -qm code
check "PR, docs + code branch" "$R" "gh pr create --draft" deny
g switch -q main && g switch -q -c chore/none
check "PR, no changes vs base" "$R" "gh pr create --draft" allow

# Internal errors block instead of allowing (simulated with an unset variable)
FAKE_HOOK="$TMP/broken-hook.sh"
sed 's/^trap on_exit EXIT$/&; : "$UNSET_VAR_FOR_TEST"/' "$HOOK" >"$FAKE_HOOK"
grep -q UNSET_VAR_FOR_TEST "$FAKE_HOOK" || echo "WARN  error injection didn't apply"
for c in "git commit -m x" "gh pr create --draft"; do
  rc=0
  jq -n --arg c "$c" --arg d "$R" '{tool_input: {command: $c}, cwd: $d}' | bash "$FAKE_HOOK" >/dev/null 2>&1 || rc=$?
  if [ "$rc" = 2 ]; then printf 'PASS  %s\n' "internal error exits 2 ($c)"; else
    printf 'FAIL  %s (exit %s)\n' "internal error exits 2 ($c)" "$rc"
    failures=$((failures + 1))
  fi
done

echo
if [ "$failures" -gt 0 ]; then
  echo "$failures test(s) failed"
  exit 1
fi
echo "All tests passed"
