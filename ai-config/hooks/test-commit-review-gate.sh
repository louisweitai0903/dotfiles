#!/usr/bin/env bash
# Tests for commit-review-gate.sh: feeds hook JSON for each scenario against a
# throwaway git repo and checks the allow/deny decision. Exits non-zero on any
# failure. Usage: ./hooks/test-commit-review-gate.sh
set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commit-review-gate.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export COMMIT_REVIEW_GATE_LOG="$TMP/gate.log"
R="$TMP/repo"
OUT="$TMP/notrepo"
mkdir -p "$R" "$OUT"
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

g init -q && g config user.email test@example.com && g config user.name test
echo a >"$R/app.txt" && g add . && g commit -qm init

# Not a commit
check "non-commit command" "$R" "ls -la" allow
check "git add alone" "$R" "git add app.txt" allow
check "git commit-tree" "$R" "git commit-tree abc" allow
check "git log --grep commit" "$R" "git log --grep commit" allow
check "echo mentioning git commit" "$R" 'echo "run git commit later"' allow
check "grep for git commit -m" "$R" "grep -rn 'git commit -m' docs" allow

# Nothing staged
check "nothing staged" "$R" "git commit -m x" deny
check "message-only amend" "$R" "git commit --amend -m x" allow
check "allow-empty" "$R" "git commit --allow-empty -m x" allow
check "pathspec, nothing staged" "$R" "git commit app.txt -m x" deny
check "outside any repo" "$OUT" "git commit -m x" allow

# Code staged, no review
echo b >>"$R/app.txt" && g add app.txt
check "staged code, no review" "$R" "git commit -m 'fix a bug'" deny
check "plain git commit, no review" "$R" "git commit" deny
check "git commit;" "$R" "git commit;" deny
check "git commit && git push" "$R" "git commit && git push" deny
check "-C plain commit from outside" "$OUT" "git -C $R commit" deny
check "git -C text in message" "$R" "git commit -m 'see git -C /tmp'" deny
check "-C with a variable path" "$OUT" 'git -C "$REPO" commit -m x' deny
check "cd && commit" "$R" "cd $R && git commit -m x" deny
check "git -c option" "$R" "git -c core.editor=true commit -m x" deny
check "amend adding code to unreviewed HEAD" "$R" "git commit --amend --no-edit" deny
check "-C from another dir" "$OUT" "git -C $R commit -m x" deny
check "-C quoted path" "$OUT" "git -C '$R' commit -m x" deny

# Code + review staged
mkdir -p "$R/docs/reviews" && echo r >"$R/docs/reviews/2026-01-01-x.md" && g add docs
check "staged code + review" "$R" "git commit -m x" allow
check "plain git commit + review" "$R" "git commit" allow
check "-C quoted path + review" "$OUT" "git -C '$R' commit -m x" allow
check "two quoted -C paths (ambiguous)" "$OUT" "git -C '$OUT' status && git -C '$R' commit -m x" deny
check "cd <repo> && commit + review" "$OUT" "cd $R && git commit -m x" allow
check "cd <non-repo> && commit" "$R" "cd $OUT && git commit -m x" deny
check "cd quoted path && commit" "$OUT" "cd '$R' && git commit -m x" deny
check "cd variable && commit" "$OUT" 'cd $REPO && git commit -m x' deny
check "message mentions git add" "$R" "git commit -m 'docs -- explain why git add must run separately'" allow
check "heredoc message mentions git rm" "$R" "$(printf 'git commit -m "$(cat <<%sEOF%s\nfix[x] -- y\n\nNever chain git rm or git add with commit.\nEOF\n)"' "'" "'")" allow
check "unquoted heredoc message" "$R" "$(printf 'git commit -F - <<EOF\nfix[x] -- y\nEOF')" allow
check "heredoc body with quoted phrase" "$R" "$(printf 'git commit -m "$(cat <<%sEOF%s\nfix: "a b" c\n\nsee "docs/x y" and git add notes\nEOF\n)"' "'" "'")" allow
check "escaped quotes in -m" "$R" 'git commit -m "say \"hi\""' allow
check "/usr/bin/git commit detected" "$R" "/usr/bin/git commit -m x app.txt" deny
check "--git-dir X commit detected" "$R" "git --git-dir .git commit -m x app.txt" deny
check "redirect after commit" "$R" "git commit -m x 2>&1" allow
check "add && commit" "$R" "git add app.txt && git commit -m x" deny
check "-C add && -C commit" "$OUT" "git -C $R add . && git -C $R commit -m x" deny
check "pathspec with review staged" "$R" "git commit -m x app.txt" deny
check "-- pathspec" "$R" "git commit -m x -- app.txt" deny
check "--only" "$R" "git commit -o -m x app.txt" deny
check "--include" "$R" "git commit -i app.txt -m x" deny

# Monorepo review location
g reset -q docs && mkdir -p "$R/pkg/a/docs/reviews" && echo r >"$R/pkg/a/docs/reviews/2026-01-01-y.md" && g add pkg
check "subproject review" "$R" "git commit -m x" allow
g reset -q pkg && echo r >"$R/docs/reviews/2026-01-01-café.md" && g add "docs/reviews/2026-01-01-café.md"
check "non-ASCII review filename" "$R" "git commit -m x" allow
g rm -q --cached "docs/reviews/2026-01-01-café.md" && rm "$R/docs/reviews/2026-01-01-café.md"
g add docs && g commit -qm reviewed

# -a / --amend against a reviewed HEAD
echo c >>"$R/app.txt" && echo r2 >>"$R/docs/reviews/2026-01-01-x.md"
check "-am with modified review" "$R" "git commit -am x" allow
check "-a with modified review" "$R" "git commit -a -m x" allow
g checkout -q docs/reviews/2026-01-01-x.md
check "-a, review unchanged" "$R" "git commit -a -m x" deny
check "-C with -am" "$OUT" "git -C $R commit -am x" deny
echo r3 >>"$R/docs/reviews/2026-01-01-x.md" && g add app.txt
check "-la in message is not -a" "$R" "git commit -m '-la'" deny
check "odd quote + -a in heredoc body" "$R" "$(printf 'git commit -m "$(cat <<%sEOF%s\nfix: "x -a\nEOF\n)"' "'" "'")" deny
g checkout -q docs/reviews/2026-01-01-x.md
check "amend adding code to reviewed HEAD" "$R" "git commit --amend --no-edit" allow
g reset -q && g checkout -q . && g rm -q app.txt
check "delete-only, no review" "$R" "git commit -m x" deny
g reset -q && g checkout -q . && g rm -q --cached docs/reviews/2026-01-01-x.md
check "deleted review doesn't count" "$R" "git commit -m x" deny

# Internal errors block instead of allowing (simulated with an unset variable)
FAKE_HOOK="$TMP/broken-hook.sh"
sed 's/^trap on_exit EXIT$/&; : "$UNSET_VAR_FOR_TEST"/' "$HOOK" >"$FAKE_HOOK"
grep -q UNSET_VAR_FOR_TEST "$FAKE_HOOK" || echo "WARN  error injection didn't apply"
rc=0
jq -n --arg c "git commit -m x" --arg d "$R" '{tool_input: {command: $c}, cwd: $d}' | bash "$FAKE_HOOK" >/dev/null 2>&1 || rc=$?
if [ "$rc" = 2 ]; then printf 'PASS  %s\n' "internal error exits 2 (blocks)"; else
  printf 'FAIL  %s (exit %s)\n' "internal error exits 2 (blocks)" "$rc"
  failures=$((failures + 1))
fi

echo
if [ "$failures" -gt 0 ]; then
  echo "$failures test(s) failed"
  exit 1
fi
echo "All tests passed"
