#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

# Static contract: the launcher must clear Hyprland fullscreen before exec so
# on_focus_under_fullscreen cannot hand it to the Chromium --app window.
grep -q 'fullscreen_state({ internal = 0, client = 0 })' "$ROOT/bin/omarchy-launch-webapp" ||
  fail "launch-webapp clears compositor fullscreen before launch"
grep -q 'fullscreenstate 0 0' "$ROOT/bin/omarchy-launch-webapp" ||
  fail "launch-webapp falls back to the legacy fullscreenstate dispatch"
grep -q '(.fullscreen // 0) > 0' "$ROOT/bin/omarchy-launch-webapp" ||
  fail "launch-webapp only clears fullscreen when the focused window is fullscreen"
grep -q -- '--app=' "$ROOT/bin/omarchy-launch-webapp" ||
  fail "launch-webapp still launches Chromium --app"
pass "launch-webapp clears Hyprland fullscreen before opening a web app"

# Learn -> Omarchy still routes through the webapp launcher.
grep -q "omarchy-launch-webapp 'https://omarchy.org/manual/'" \
  "$ROOT/default/omarchy/omarchy-menu.jsonc" ||
  fail "Learn -> Omarchy still uses omarchy-launch-webapp"
pass "Learn -> Omarchy still uses omarchy-launch-webapp"
