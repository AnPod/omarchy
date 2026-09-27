#!/bin/bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"
conf="$ROOT/default/modprobe.d/omarchy-thinkpad-hotkey.conf"
[[ -f $conf ]] || fail "thinkpad hotkey modprobe drop-in missing"
grep -q 'hotkey_mask=' "$conf" || fail "drop-in sets hotkey_mask"
grep -q 'thinkpad-hotkey' "$ROOT/install/hardware/all.sh" || fail "hardware install runs thinkpad-hotkey"
grep -q 'omarchy-thinkpad-hotkey.conf' "$ROOT/migrations/1790544000.sh" || fail "migration installs hotkey drop-in"
pass "ThinkPad Bluetooth F10 hotkey mask is shipped"
