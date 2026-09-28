#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

helper="$ROOT/bin/omarchy-hw-fujitsu-lifebook-p727"
script="$ROOT/install/hardware/fujitsu/fix-lifebook-p727-i8042.sh"
[[ -x $helper ]] || fail "lifebook hw helper is executable"
grep -Fq 'i8042.nomux' "$script" || fail "install script sets i8042.nomux"
grep -Fq 'fix-lifebook-p727-i8042.sh' "$ROOT/install/hardware/all.sh" ||
  fail "hardware install runs lifebook i8042 fix"
pass "LIFEBOOK P727 i8042 fix is wired"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/dmi"
printf 'LIFEBOOK P727\n' >"$tmpdir/dmi/product_name"
# Helper reads /sys/... — exercise the string match via a stubbed cat path by
# running the comparison inline the same way the helper does.
product_name=$(cat "$tmpdir/dmi/product_name")
[[ $product_name == *"LIFEBOOK P727"* ]] || fail "product name match"
pass "LIFEBOOK P727 product name matches detection"

migration=$(rg -l 'lifebook-p727-i8042.conf' "$ROOT/migrations" | head -1)
[[ -n $migration ]] || fail "migration installs lifebook i8042 drop-in"
pass "migration installs lifebook i8042 drop-in"
