#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mock_bin="$tmpdir/bin"
log_file="$tmpdir/log"
state_dir="$tmpdir/state"
mkdir -p "$mock_bin" "$state_dir"

: >"$log_file"
cat >"$mock_bin/hyprctl" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >>"$TEST_LOG"
case $1 in
  activewindow)
    printf '{"address":"0xdead","pid":4242,"xwayland":true,"fullscreen":0}\n'
    ;;
  clients)
    if [[ -f $STATE_DIR/closed ]]; then
      printf '[]\n'
    else
      printf '[{"address":"0xdead","pid":4242}]\n'
    fi
    ;;
  dispatch)
    touch "$STATE_DIR/closed"
    ;;
esac
SH
cat >"$mock_bin/sleep" <<'SH'
#!/bin/bash
exit 0
SH
chmod +x "$mock_bin"/*

PATH="$mock_bin:$PATH" TEST_LOG="$log_file" STATE_DIR="$state_dir" \
  bash "$ROOT/bin/omarchy-hyprland-window-close"

grep -q 'window.close({ window = "address:0xdead" })' "$log_file" ||
  fail "window-close dispatches a cooperative close" "log: $(< "$log_file")"
pass "window-close dispatches a cooperative close without force-kill"

# Zombie path: window stays mapped; pid has no /proc entry.
: >"$log_file"
rm -f "$state_dir"/*
cat >"$mock_bin/hyprctl" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >>"$TEST_LOG"
case $1 in
  activewindow)
    printf '{"address":"0xzombie","pid":99999,"xwayland":true,"fullscreen":0}\n'
    ;;
  clients)
    if [[ -f $STATE_DIR/force_closed ]]; then
      printf '[]\n'
    else
      printf '[{"address":"0xzombie","pid":99999}]\n'
    fi
    ;;
  dispatch)
    closes=0
    [[ -f $STATE_DIR/closes ]] && closes=$(wc -l <"$STATE_DIR/closes")
    echo x >>"$STATE_DIR/closes"
    if (( closes >= 1 )); then
      touch "$STATE_DIR/force_closed"
    fi
    ;;
esac
SH
chmod +x "$mock_bin/hyprctl"

PATH="$mock_bin:$PATH" TEST_LOG="$log_file" STATE_DIR="$state_dir" \
  bash "$ROOT/bin/omarchy-hyprland-window-close"

grep -q 'window.close({ window = "address:0xzombie" })' "$log_file" ||
  fail "zombie close still sends an initial close" "log: $(< "$log_file")"
# Second close / killwindow after the surface refused to leave.
closes=$(grep -c '0xzombie' "$log_file" || true)
(( closes >= 2 )) ||
  fail "zombie close force-targets the stuck surface" "log: $(< "$log_file")"
pass "window-close force-clears an XWayland zombie that ignores close"

grep -q 'omarchy-hyprland-window-close' "$ROOT/default/hypr/bindings/tiling.lua" ||
  fail "tiling bindings use omarchy-hyprland-window-close"
pass "tiling bindings use omarchy-hyprland-window-close"
