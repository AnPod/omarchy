#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

home="$test_dir/home"
stub_bin="$test_dir/bin"
mkdir -p "$home/.local/bin" "$home/.local/state/omarchy" "$stub_bin"

# Real omarchy-mise-install writes wrappers; stub mise so settings/up succeed
# without touching a real mise install.
cat >"$stub_bin/mise" <<'SH'
#!/bin/bash
exit 0
SH
chmod +x "$stub_bin/mise"

export HOME="$home"
export OMARCHY_PATH="$ROOT"
export PATH="$stub_bin:$ROOT/bin:$PATH"

# Clearing ~/.local/bin must not permanently lose the documented stubs: update
# reinstalls them from install/user/mise.sh on every run.
rm -rf "$home/.local/bin"
mkdir -p "$home/.local/bin"

"$ROOT/bin/omarchy-update-mise" >/dev/null

[[ -x $home/.local/bin/gh ]] ||
  fail "omarchy-update-mise restores the gh stub after ~/.local/bin is cleared"
grep -qF 'mise use -g --quiet "gh"' "$home/.local/bin/gh" ||
  fail "restored gh stub is a mise wrapper" "$(cat "$home/.local/bin/gh")"
[[ -x $home/.local/bin/claude ]] ||
  fail "omarchy-update-mise restores other default stubs with gh"
pass "omarchy-update-mise restores default stubs after ~/.local/bin is cleared"

# Remove Preinstalls opted out of the stubs; update must not put them back.
rm -rf "$home/.local/bin"
mkdir -p "$home/.local/bin"
touch "$home/.local/state/omarchy/preinstalls-removed"

"$ROOT/bin/omarchy-update-mise" >/dev/null

[[ ! -e $home/.local/bin/gh ]] ||
  fail "omarchy-update-mise leaves stubs removed after Remove Preinstalls"
pass "omarchy-update-mise respects the preinstalls opt-out"

# The PATH-recursion migration used to iterate only existing wrappers, so an
# empty ~/.local/bin made it a no-op. It now falls back to the canonical list.
rm -f "$home/.local/state/omarchy/preinstalls-removed"
rm -rf "$home/.local/bin"
mkdir -p "$home/.local/bin"

bash -euo pipefail "$ROOT/migrations/1784909971.sh" >/dev/null

[[ -x $home/.local/bin/gh ]] ||
  fail "migration 1784909971 restores stubs when ~/.local/bin is empty"
pass "migration 1784909971 falls back to install/user/mise.sh when empty"

# With the opt-out set, the empty-bin fallback must not recreate stubs.
rm -rf "$home/.local/bin"
mkdir -p "$home/.local/bin"
touch "$home/.local/state/omarchy/preinstalls-removed"

bash -euo pipefail "$ROOT/migrations/1784909971.sh" >/dev/null

[[ ! -e $home/.local/bin/gh ]] ||
  fail "migration 1784909971 empty-bin fallback respects Remove Preinstalls"
pass "migration 1784909971 empty-bin fallback respects the preinstalls opt-out"
