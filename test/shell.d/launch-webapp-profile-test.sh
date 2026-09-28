#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

stub_dir="$tmpdir/bin"
home_dir="$tmpdir/home"
mkdir -p "$stub_dir" "$home_dir/.local/share/applications" "$tmpdir/usr/share/applications"

cat >"$home_dir/.local/share/applications/chromium.desktop" <<'DESK'
[Desktop Entry]
Exec=/usr/bin/chromium %U
DESK

cat >"$stub_dir/xdg-settings" <<'SH'
#!/bin/bash
printf 'google-chrome.desktop\n'
SH
chmod +x "$stub_dir/xdg-settings"

cat >"$stub_dir/setsid" <<'SH'
#!/bin/bash
# setsid program args — run the program without a new session in tests.
exec "$@"
SH
chmod +x "$stub_dir/setsid"

cat >"$stub_dir/uwsm-app" <<'SH'
#!/bin/bash
# Record the launched argv, then exit successfully (no real browser).
printf '%s\n' "$@" >"$LAUNCH_LOG"
exit 0
SH
chmod +x "$stub_dir/uwsm-app"

# sed in launch-webapp looks at {~/.local,~/.nix-profile,/usr}/share/applications/
# HOME controls ~/.local; also provide /usr via a PATH wrapper that doesn't help sed.
# The script expands braces with the real /usr — stage a fake by rewriting HOME only
# and pointing the desktop at our home path (already done). ~/.local is enough.

export HOME="$home_dir"
export XDG_DATA_HOME="$home_dir/.local/share"
export PATH="$stub_dir:$PATH"
export LAUNCH_LOG="$tmpdir/launch.log"

"$ROOT/bin/omarchy-launch-webapp" "https://messages.google.com/web/conversations?x=1" --foo ||
  fail "launch-webapp exits cleanly"

grep -q -- '--app=https://messages.google.com/web/conversations?x=1' "$LAUNCH_LOG" ||
  fail "launch-webapp passes --app URL" "$(cat "$LAUNCH_LOG")"
grep -q -- '--user-data-dir='"$XDG_DATA_HOME"'/omarchy/webapps/messages-google-com-web-conversations' "$LAUNCH_LOG" ||
  fail "launch-webapp uses a stable per-URL user-data-dir" "$(cat "$LAUNCH_LOG")"
[[ -d $XDG_DATA_HOME/omarchy/webapps/messages-google-com-web-conversations ]] ||
  fail "launch-webapp creates the per-app profile directory"
pass "launch-webapp pins a per-URL Chromium profile"

# Same host/path (ignoring query) must reuse the directory.
: >"$LAUNCH_LOG"
"$ROOT/bin/omarchy-launch-webapp" "https://messages.google.com/web/conversations#inbox" ||
  fail "launch-webapp exits cleanly on fragment URL"
grep -q -- '--user-data-dir='"$XDG_DATA_HOME"'/omarchy/webapps/messages-google-com-web-conversations' "$LAUNCH_LOG" ||
  fail "launch-webapp reuses the profile across query/fragment variants" "$(cat "$LAUNCH_LOG")"
pass "launch-webapp reuses the profile across query/fragment variants"
