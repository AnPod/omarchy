#!/bin/bash

set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/bin"
export EDIT_ARGS="$scratch/args"
cat >"$scratch/bin/tensaku" <<'STUB'
#!/bin/bash
printf '%s\0' "$@" >"$EDIT_ARGS"
exit "${EDIT_EXIT:-0}"
STUB
chmod +x "$scratch/bin/tensaku"
export PATH="$scratch/bin:$PATH"
image="$scratch/a screenshot.png"
touch "$image"

"$ROOT/bin/omarchy-capture-edit" "$image"
python3 - "$EDIT_ARGS" "$image" <<'PY'
import sys
from pathlib import Path
args = Path(sys.argv[1]).read_bytes().split(b'\0')[:-1]
image = sys.argv[2].encode()
assert args == [b'--filename', image, b'--output-filename', image,
                b'--actions-on-enter', b'save-to-clipboard', b'--save-after-copy',
                b'--copy-command', b'wl-copy', b'--early-exit'], args
PY
pass "screenshot editor saves to the original file, copies, and exits with paths intact"

set +e
EDIT_EXIT=23 "$ROOT/bin/omarchy-capture-edit" "$image"
status=$?
set -e
(( status == 23 )) || fail "screenshot editor preserves Tensaku failures"
pass "screenshot editor preserves Tensaku failures"

rm "$EDIT_ARGS"
if "$ROOT/bin/omarchy-capture-edit" "$scratch/missing.png" >/dev/null 2>&1; then
  fail "missing image is rejected"
fi
[[ ! -e $EDIT_ARGS ]] || fail "missing image does not launch Tensaku"
pass "missing image does not launch Tensaku"
