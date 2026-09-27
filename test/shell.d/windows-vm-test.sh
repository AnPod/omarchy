#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

windows_vm_command="$ROOT/bin/omarchy-windows-vm"
windows_vm_rules="$ROOT/default/hypr/apps/windows-vm.lua"

rg -q '^    restart: "no"$' "$windows_vm_command" ||
  fail "Windows VM uses manual startup by default"
pass "Windows VM uses manual startup by default"

if rg -q '^    restart: unless-stopped$' "$windows_vm_command"; then
  fail "Windows VM does not restart automatically at boot"
fi
pass "Windows VM does not restart automatically at boot"

# Tolerate either shell quoting of the argument -- what must not drift is the
# title itself, since the Hyprland rule below matches on it.
rg -q 'title:"?Windows VM - Omarchy"' "$windows_vm_command" ||
  fail "Windows VM launches FreeRDP with its expected title"
rg -q 'class = "\^xfreerdp\$", title = "\^Windows VM - Omarchy\$"' "$windows_vm_rules" ||
  fail "Windows VM opacity rule targets its FreeRDP window"
rg -q 'tag = "-default-opacity"' "$windows_vm_rules" ||
  fail "Windows VM opts out of default opacity"
rg -q 'opacity = "1 1"' "$windows_vm_rules" ||
  fail "Windows VM stays fully opaque"
pass "Windows VM stays fully opaque"

# chmod 0700 leaves setgid on directories; the container sets ~/Windows to 2777,
# so relaunch prep must use 00700 to clear it before the exact-700 check.
rg -q 'chmod 00700 -- "/proc/\$BASHPID/fd/\$storage_fd" "/proc/\$BASHPID/fd/\$shared_fd"' "$windows_vm_command" ||
  fail "caller-mount prep clears setgid when hardening VM folders"
rg -q 'chmod 00700 -- "\$storage" "\$shared"' "$windows_vm_command" ||
  fail "user-mount prep clears setgid when hardening VM folders"
if rg -q 'chmod 0700 -- "/proc/\$BASHPID/fd/\$storage_fd"' "$windows_vm_command" ||
  rg -q 'chmod 0700 -- "\$storage" "\$shared"' "$windows_vm_command"; then
  fail "VM folder hardening still uses chmod 0700, which preserves setgid"
fi
pass "Windows VM folder hardening clears setgid on relaunch"

# Document the GNU chmod quirk the hardening sites rely on: a 4-digit mode
# leaves setgid on directories, while a leading 0 clears it.
setgid_dir=$(mktemp -d)
chmod 2777 "$setgid_dir"
[[ $(stat -c %a "$setgid_dir") == 2777 ]] || fail "could not seed setgid directory"
chmod 0700 -- "$setgid_dir"
[[ $(stat -c %a "$setgid_dir") == 2700 ]] || fail "chmod 0700 unexpectedly cleared setgid"
chmod 00700 -- "$setgid_dir"
[[ $(stat -c %a "$setgid_dir") == 700 ]] || fail "chmod 00700 did not clear setgid"
rmdir "$setgid_dir"
pass "GNU chmod 00700 clears directory setgid; 0700 does not"
