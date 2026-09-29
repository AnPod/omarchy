#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

conf="$ROOT/etc/tlp.d/omarchy-bluetooth-usb.conf"
[[ -f $conf ]] || fail "tlp bluetooth usb drop-in exists"
grep -Fq 'USB_DENYLIST+=' "$conf" || fail "drop-in appends USB_DENYLIST"
grep -Fq '8087:0aaa' "$conf" || fail "drop-in excludes verified Intel 9460 BT id"
pass "tlp bluetooth usb drop-in excludes Intel combo cards"

grep -Fq "/etc/tlp.d/omarchy-bluetooth-usb.conf" "$ROOT/bin/omarchy-upgrade-to-quattro" ||
  fail "upgrade-to-quattro overwrites the tlp bluetooth drop-in"
pass "upgrade-to-quattro overwrites the tlp bluetooth drop-in"

migration=$(rg -l 'omarchy-bluetooth-usb.conf' "$ROOT/migrations" | head -1)
[[ -n $migration ]] || fail "migration installs tlp bluetooth drop-in"
pass "migration installs tlp bluetooth drop-in"
