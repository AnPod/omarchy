#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
mkdir -p "$stub_bin"

cat >"$stub_bin/pacman" <<'SH'
#!/bin/bash
# Pretend two orphans exist.
if [[ $1 == "-Qtdq" ]]; then
  printf '%s\n' orphan-a orphan-b
  exit 0
fi
exit 0
SH
chmod +x "$stub_bin/pacman"

cat >"$stub_bin/gum" <<'SH'
#!/bin/bash
echo "gum should not run in unattended mode" >&2
exit 1
SH
chmod +x "$stub_bin/gum"

# Allocate a TTY so the old tty-only gate would have called gum confirm.
script_output=$(mktemp)
if ! script -qefc "
  export PATH='$stub_bin:$ROOT/bin:$PATH'
  export OMARCHY_UPDATE_UNATTENDED=1
  omarchy-update-orphan-pkgs
" /dev/null >"$script_output" 2>&1; then
  fail "unattended orphan step should exit 0" "$(cat "$script_output")"
fi
grep -q 'orphaned package' "$script_output" || fail "unattended orphan step reports orphans" "$(cat "$script_output")"
grep -q 'gum should not run' "$script_output" && fail "unattended orphan step must not call gum" "$(cat "$script_output")"
pass "unattended orphan step skips gum confirm on a TTY"
