#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

helper="$ROOT/bin/omarchy-chromium-nvidia-video-flags"
[[ -x $helper ]] || fail "nvidia chromium video helper is executable"
pass "nvidia chromium video helper is executable"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/.config" "$tmp/devices"

# Stub GSP detector success.
cat >"$tmp/bin/omarchy-hw-nvidia-gsp" <<'STUB'
#!/bin/bash
exit 0
STUB
chmod +x "$tmp/bin/omarchy-hw-nvidia-gsp"

cat >"$tmp/.config/chromium-flags.conf" <<'CONF'
--ozone-platform=wayland
CONF

HOME="$tmp" PATH="$tmp/bin:$PATH" "$helper"

grep -qxF -- '--disable-accelerated-video-decode' "$tmp/.config/chromium-flags.conf" ||
  fail "helper appends disable-accelerated-video-decode on GSP" "$(cat "$tmp/.config/chromium-flags.conf")"
pass "helper appends disable-accelerated-video-decode on GSP"

HOME="$tmp" PATH="$tmp/bin:$PATH" "$helper"
[[ $(grep -cF -- '--disable-accelerated-video-decode' "$tmp/.config/chromium-flags.conf") == 1 ]] ||
  fail "helper is idempotent"
pass "helper is idempotent"

# Non-GSP is a no-op.
cat >"$tmp/bin/omarchy-hw-nvidia-gsp" <<'STUB'
#!/bin/bash
exit 1
STUB
chmod +x "$tmp/bin/omarchy-hw-nvidia-gsp"
rm -f "$tmp/.config/brave-flags.conf"
: >"$tmp/.config/brave-flags.conf"
HOME="$tmp" PATH="$tmp/bin:$PATH" "$helper"
! grep -q -- '--disable-accelerated-video-decode' "$tmp/.config/brave-flags.conf" ||
  fail "helper skips non-GSP machines"
pass "helper skips non-GSP machines"

grep -q 'omarchy-chromium-nvidia-video-flags' "$ROOT/install/hardware/nvidia.sh" ||
  fail "nvidia install applies chromium video flags"
pass "nvidia install applies chromium video flags"

grep -q 'omarchy-chromium-nvidia-video-flags' "$ROOT/bin/omarchy-install-browser" ||
  fail "browser install applies chromium video flags"
pass "browser install applies chromium video flags"
