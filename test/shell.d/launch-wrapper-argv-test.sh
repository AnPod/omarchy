#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
stub_dir="$tmpdir/bin"
mkdir -p "$stub_dir"
log="$tmpdir/log"

cat >"$stub_dir/omarchy-launch-or-focus" <<'SH'
#!/bin/bash
printf 'pattern=%s\n' "$1" >>"$LAUNCH_LOG"
printf 'command=%s\n' "$2" >>"$LAUNCH_LOG"
SH
chmod +x "$stub_dir/omarchy-launch-or-focus"

cat >"$stub_dir/hyprctl" <<'SH'
#!/bin/bash
printf '[]\n'
SH
chmod +x "$stub_dir/hyprctl"

export PATH="$stub_dir:$PATH"
export LAUNCH_LOG="$log"

: >"$log"
"$ROOT/bin/omarchy-launch-or-focus-webapp" 'Chat App' 'https://example.com/a b' --flag='x y' ||
  fail "webapp wrapper exits cleanly"
grep -Fx "pattern=Chat App" "$log" || fail "webapp wrapper preserves window pattern" "$(cat "$log")"
grep -E '^command=omarchy-launch-webapp' "$log" || fail "webapp wrapper builds launch command" "$(cat "$log")"
cmd=$(awk -F= '/^command=/{print substr($0,9)}' "$log")
# Re-parse the way omarchy-launch-or-focus does.
eval "set -- $cmd"
[[ $1 == omarchy-launch-webapp ]] || fail "re-parse keeps launch-webapp" "$*"
[[ $2 == 'https://example.com/a b' ]] || fail "re-parse keeps spaced URL" "$*"
[[ $3 == '--flag=x y' ]] || fail "re-parse keeps spaced flag" "$*"
pass "webapp wrapper quotes argv for launch-or-focus re-parse"

: >"$log"
"$ROOT/bin/omarchy-launch-or-focus-webapp" 'Chat' ||
  fail "webapp wrapper allows pattern-only invoke"
grep -Fx 'command=omarchy-launch-webapp' "$log" ||
  fail "empty argv does not invent a quoted empty URL" "$(cat "$log")"
pass "webapp wrapper does not invent an empty URL argument"

: >"$log"
"$ROOT/bin/omarchy-launch-or-focus-tui" --app-id=org.omarchy.htop htop --sort='CPU %' ||
  fail "tui wrapper exits cleanly"
cmd=$(awk -F= '/^command=/{print substr($0,9)}' "$log")
eval "set -- $cmd"
[[ $1 == omarchy-launch-tui && $2 == --app-id=org.omarchy.htop && $3 == htop && $4 == '--sort=CPU %' ]] ||
  fail "tui wrapper quotes spaced args" "$*"
pass "tui wrapper quotes argv for launch-or-focus re-parse"

# basename and --app-id must stay quoted for paths with spaces.
cat >"$stub_dir/setsid" <<'SH'
#!/bin/bash
exec "$@"
SH
chmod +x "$stub_dir/setsid"
cat >"$stub_dir/uwsm-app" <<'SH'
#!/bin/bash
printf '%s\n' "$@" >"$LAUNCH_LOG"
SH
chmod +x "$stub_dir/uwsm-app"
cat >"$stub_dir/xdg-terminal-exec" <<'SH'
#!/bin/bash
printf 'xdg-terminal-exec\n' >>"$LAUNCH_LOG"
printf '%s\n' "$@" >>"$LAUNCH_LOG"
SH
chmod +x "$stub_dir/xdg-terminal-exec"

: >"$log"
"$ROOT/bin/omarchy-launch-tui" "/tmp/my tools/htop" || fail "launch-tui exits cleanly"
grep -Fx -- '--app-id=org.omarchy.htop' "$log" ||
  fail "launch-tui quotes app-id from basename" "$(cat "$log")"
pass "launch-tui quotes app-id and command path"
