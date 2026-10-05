#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
mkdir -p "$mock_bin"

cat >"$mock_bin/pacman" <<'SH'
#!/bin/bash
[[ ${OMARCHY_TEST_ZED_AVAILABLE:-0} == "1" ]]
SH

cat >"$mock_bin/omarchy-pkg-add" <<'SH'
#!/bin/bash
printf 'pkg:%s\n' "$*" >>"$OMARCHY_TEST_LOG"
SH

cat >"$mock_bin/curl" <<'SH'
#!/bin/bash
printf 'curl:%s\n' "$*" >>"$OMARCHY_TEST_LOG"
printf '%s\n' 'printf "upstream-installer\\n" >>"$OMARCHY_TEST_LOG"'
SH

for command in omazed setsid; do
  cat >"$mock_bin/$command" <<'SH'
#!/bin/bash
exit 0
SH
done

chmod +x "$mock_bin"/*

export OMARCHY_TEST_LOG="$test_tmp/install.log"
export PATH="$mock_bin:$PATH"

OMARCHY_TEST_ZED_AVAILABLE=1 bash "$ROOT/bin/omarchy-install-editor-zed"
grep -Fxq 'pkg:zed omazed' "$OMARCHY_TEST_LOG" ||
  fail "repo-available Zed installs in the existing package transaction"
if grep -q '^curl:' "$OMARCHY_TEST_LOG"; then
  fail "repo-available Zed does not run the upstream installer"
fi
pass "repo-available Zed uses the existing package transaction"

: >"$OMARCHY_TEST_LOG"
OMARCHY_TEST_ZED_AVAILABLE=0 bash "$ROOT/bin/omarchy-install-editor-zed"
grep -Fxq 'pkg:omazed' "$OMARCHY_TEST_LOG" ||
  fail "repo-unavailable Zed installs omazed separately"
grep -Fxq 'curl:-fsSL https://zed.dev/install.sh' "$OMARCHY_TEST_LOG" ||
  fail "repo-unavailable Zed downloads the official installer"
grep -Fxq 'upstream-installer' "$OMARCHY_TEST_LOG" ||
  fail "repo-unavailable Zed runs the official installer"
pass "repo-unavailable Zed installs omazed and runs the official installer"
