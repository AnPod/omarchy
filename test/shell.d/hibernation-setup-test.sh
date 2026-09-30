#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
export fixture
export OMARCHY_PATH="$ROOT"
mkdir -p "$fixture/bin"
export PATH="$fixture/bin:$HOME/.local/bin:$PATH"

# Redirect system paths in a temporary copy; never run setup against the host.
python3 - "$ROOT/bin/omarchy-hibernation-setup" "$fixture/setup" "$fixture" <<'PY'
import sys
from pathlib import Path
source, target, fixture = sys.argv[1:]
script = Path(source).read_text()
for path in ('/etc/', '/sys/power/', '/swap/', '/usr/lib/systemd/system-sleep/'):
    script = script.replace(path, fixture + path)
script = script.replace('SWAP_SUBVOLUME="/swap"', f'SWAP_SUBVOLUME="{fixture}/swap"')
Path(target).write_text(script)
PY

cat > "$fixture/bin/sudo" <<'STUB'
#!/bin/bash
# The fixture hook does not need root ownership.
if [[ $1 == "/usr/bin/install" ]]; then
  shift
  exec /usr/bin/install -m "$2" -T "${@: -2}"
else
  exec "$@"
fi
STUB
cat > "$fixture/bin/findmnt" <<'STUB'
#!/bin/bash
printf '%s\n' "$DEVICE"
STUB
cat > "$fixture/bin/btrfs" <<'STUB'
#!/bin/bash
if [[ $1 == "inspect-internal" ]]; then
  printf '%s\n' "$OFFSET"
fi
STUB
cat > "$fixture/bin/swapon" <<'STUB'
#!/bin/bash
if [[ $1 == "--show" ]]; then
  printf '%s\n' "$fixture/swap/swapfile"
fi
STUB
cat > "$fixture/bin/limine-mkinitcpio" <<'STUB'
#!/bin/bash
printf 'rebuild\n' >> "$fixture/rebuilds"
STUB
cat > "$fixture/bin/omarchy-cmd-missing" <<'STUB'
#!/bin/bash
exit 1
STUB
cat > "$fixture/bin/swaplabel" <<'STUB'
#!/bin/bash
exit 0
STUB
chmod +x "$fixture/bin/"*

drop_in="$fixture/etc/limine-entry-tool.d/resume.conf"
marker="$fixture/etc/mkinitcpio.conf.d/omarchy_resume.conf"
export DEVICE OFFSET

reset_fixture() {
  rm -rf "$fixture/etc" "$fixture/sys" "$fixture/swap" "$fixture/usr" "$fixture/rebuilds"
  mkdir -p "$fixture/etc/limine-entry-tool.d" "$fixture/etc/mkinitcpio.conf.d" \
    "$fixture/sys/power" "$fixture/swap" "$fixture/usr/lib/systemd/system-sleep"
  touch "$fixture/sys/power/image_size" "$fixture/sys/power/mem_sleep" "$fixture/swap/swapfile"
  printf '%s none swap defaults 0 0\n' "$fixture/swap/swapfile" > "$fixture/etc/fstab"
  DEVICE='/dev/nvme0n1p2[/@swap]'
  OFFSET=12345
}

run_setup() {
  bash "$fixture/setup" --force "$@" > "$fixture/stdout" 2> "$fixture/stderr" ||
    fail "setup succeeds" "$(cat "$fixture/stderr")"
}

reset_fixture
DEVICE=''
run_setup --no-rebuild
[[ ! -e $drop_in ]] || fail "empty device prevents drop-in creation"
grep -Fx "Warning: Could not determine resume device for $fixture/swap/swapfile" "$fixture/stderr" >/dev/null ||
  fail "empty device warns on stderr"
pass "empty device prevents drop-in creation and warns"

reset_fixture
run_setup --no-rebuild
grep -Fx 'KERNEL_CMDLINE[default]+=" resume=/dev/nvme0n1p2 resume_offset=12345"' "$drop_in" >/dev/null ||
  fail "new drop-in contains device without Btrfs suffix and offset"
pass "new drop-in contains device and offset"

prepare_repair() {
  reset_fixture
  echo 'HOOKS+=(resume)' > "$marker"
  printf '# custom comment\nKERNEL_CMDLINE[default]+=" quiet resume= resume_offset=6789 splash"\n' > "$drop_in"
}

prepare_repair
run_setup
expected=$(printf '# custom comment\nKERNEL_CMDLINE[default]+=" quiet resume=/dev/nvme0n1p2 resume_offset=6789 splash"')
[[ $(cat "$drop_in") == "$expected" ]] || fail "device repair preserves offset and surrounding content"
[[ $(cat "$fixture/rebuilds") == "rebuild" ]] || fail "device repair rebuilds once"
pass "empty device is repaired and rebuilt with surrounding content preserved"

prepare_repair
DEVICE='/dev/mapper/swap\name&part|disk[/@swap]'
run_setup --no-rebuild
expected=$(printf '# custom comment\nKERNEL_CMDLINE[default]+=" quiet resume=%s resume_offset=6789 splash"' "${DEVICE%%\[*}")
[[ $(cat "$drop_in") == "$expected" ]] || fail "device repair escapes sed replacement characters"
[[ ! -e $fixture/rebuilds ]] || fail "device repair respects --no-rebuild"
pass "device repair handles sed characters and --no-rebuild"

prepare_repair
cp "$drop_in" "$fixture/original"
DEVICE=''
run_setup
cmp -s "$drop_in" "$fixture/original" || fail "unavailable device leaves broken drop-in untouched"
[[ ! -e $fixture/rebuilds ]] || fail "unavailable device does not rebuild"
pass "unavailable device leaves broken drop-in untouched"

prepare_repair
printf '# Previously had resume= blank\nKERNEL_CMDLINE[default]+=" resume=/dev/existing resume_offset=6789" # Previously had resume= blank\n' > "$drop_in"
cp "$drop_in" "$fixture/original"
run_setup
cmp -s "$drop_in" "$fixture/original" || fail "valid drop-in stays unchanged"
[[ ! -e $fixture/rebuilds ]] || fail "valid drop-in does not rebuild"
pass "valid drop-in stays unchanged"

prepare_repair
printf '# Previously had resume= blank\nKERNEL_CMDLINE[default]+=" resume= resume_offset=6789" # Previously had resume= blank\n' > "$drop_in"
run_setup
expected=$(printf '# Previously had resume= blank\nKERNEL_CMDLINE[default]+=" resume=/dev/nvme0n1p2 resume_offset=6789" # Previously had resume= blank')
[[ $(cat "$drop_in") == "$expected" ]] || fail "device repair only changes the active argument"
[[ $(cat "$fixture/rebuilds") == "rebuild" ]] || fail "active device repair rebuilds once"
pass "device repair preserves comments containing empty resume text"

prepare_repair
printf 'KERNEL_CMDLINE[default]+=" resume=/dev/existing resume_offset="\n' > "$drop_in"
run_setup
grep -Fx 'KERNEL_CMDLINE[default]+=" resume=/dev/existing resume_offset=12345"' "$drop_in" >/dev/null ||
  fail "existing empty-offset repair still works"
[[ $(cat "$fixture/rebuilds") == "rebuild" ]] || fail "offset repair still rebuilds"
pass "existing empty-offset repair still works"
