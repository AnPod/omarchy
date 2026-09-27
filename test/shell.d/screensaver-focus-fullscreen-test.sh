#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

screensaver="$ROOT/bin/omarchy-screensaver"

grep -q 'undo_focus_stolen_fullscreen' "$screensaver" || \
  fail "screensaver must undo fullscreen stolen via on_focus_under_fullscreen"
grep -q 'exit_screensaver 1' "$screensaver" || \
  fail "focus-loss exit must pass the focus-lost flag"
grep -q 'fullscreenstate 0 0\|fullscreen_state' "$screensaver" || \
  fail "screensaver must dispatch a fullscreen clear"

# Focus-loss path calls undo; signal/key path must not.
python3 - "$screensaver" <<'PY' || fail "focus-loss vs key exit wiring is wrong"
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text()
assert "undo_focus_stolen_fullscreen" in text
assert re.search(r"if \(\( focus_lost \)\)", text)
assert "exit_screensaver 0" in text and "exit_screensaver 1" in text
# Key/read exit stays at 0; focus-loss uses 1.
body = text[text.index("while pgrep"):]
assert "exit_screensaver 0" in body and "exit_screensaver 1" in body
assert body.index("exit_screensaver 0") < body.index("exit_screensaver 1")
print("ok")
PY

pass "screensaver clears stolen fullscreen only on focus-loss dismiss"
