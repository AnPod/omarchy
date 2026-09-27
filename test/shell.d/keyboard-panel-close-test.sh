#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

panel="$ROOT/shell/Ui/KeyboardPanel.qml"

grep -q 'owner.close() threw, forcing close' "$panel" ||
  fail "KeyboardPanel guards throwing owner close()"
pass "KeyboardPanel guards throwing owner close()"

grep -q 'root.open = false' "$panel" ||
  fail "KeyboardPanel forces open false after a throwing close"
pass "KeyboardPanel forces open false after a throwing close"

# The happy path still returns after a successful owner.close(), so normal
# panels keep driving their own hide animation.
python3 - <<'PY' "$panel" || fail "KeyboardPanel still returns after successful owner.close()"
import pathlib, sys
text = pathlib.Path(sys.argv[1]).read_text()
start = text.index("function close()")
chunk = text[start:start + 600]
assert "owner.close()" in chunk
assert "return" in chunk.split("owner.close()", 1)[1].split("catch", 1)[0]
print("ok")
PY
pass "KeyboardPanel still returns after successful owner.close()"
