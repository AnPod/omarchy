#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT
stub_bin="$test_tmp/bin"
mkdir -p "$stub_bin"

cat >"$stub_bin/omarchy-cmd-present" <<'SH'
#!/bin/bash
[[ $1 == "mise" && ${TEST_MISE_PRESENT:-1} == "1" ]]
SH

cat >"$stub_bin/mise" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >>"$TEST_MISE_LOG"
case "$1" in
  prune)
    [[ $* == "prune --yes" ]] || exit 99
    exit "${TEST_PRUNE_STATUS:-0}"
    ;;
  up)
    [[ $MISE_MINIMUM_RELEASE_AGE == "0" ]] || exit 99
    exit "${TEST_UP_STATUS:-0}"
    ;;
  *) exit 99 ;;
esac
SH
chmod +x "$stub_bin"/*

run_update() {
  TEST_MISE_LOG="$test_tmp/calls" PATH="$stub_bin:$PATH" \
    "$ROOT/bin/omarchy-update-mise" >"$test_tmp/output" 2>&1
}

run_update || fail "mise update succeeds"
[[ $(cat "$test_tmp/calls") == $'prune --yes\nup' ]] ||
  fail "unused versions are pruned before upgrading" "$(cat "$test_tmp/calls")"
pass "pruning precedes upgrading and the upgrade bypasses the release cooldown"

: >"$test_tmp/calls"
TEST_PRUNE_STATUS=1 run_update || fail "prune failure does not prevent upgrading"
[[ $(cat "$test_tmp/calls") == $'prune --yes\nup' ]] || fail "upgrade follows a failed prune"
grep -q 'Could not prune unused mise tools' "$test_tmp/output" || fail "prune failure is reported"
pass "prune failure warns and the upgrade continues"

if TEST_UP_STATUS=7 run_update; then
  fail "upgrade failure is propagated"
else
  status=$?
  (( status == 7 )) || fail "upgrade exit status is preserved" "$status"
fi
pass "upgrade failure remains visible to the update runner"

: >"$test_tmp/calls"
TEST_MISE_PRESENT=0 run_update || fail "missing mise is skipped"
[[ ! -s $test_tmp/calls ]] || fail "missing mise does not run pruning or upgrading"
pass "systems without mise skip both steps"
