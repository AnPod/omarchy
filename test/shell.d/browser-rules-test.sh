#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

browser_rules="$ROOT/default/hypr/apps/browser.lua"

rg -q 'tile = true' "$browser_rules" || fail "chromium browsers stay tiled by default"
rg -q 'Live Caption\|Live Translate\|实时字幕' "$browser_rules" ||
  fail "Live Caption bubble is not floated by title"
rg -q 'float = true' "$browser_rules" || fail "Live Caption rule sets float"
pass "Chrome Live Caption bubble floats instead of tiling"
