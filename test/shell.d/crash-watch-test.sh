#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

# omarchy-crash-watch must announce a crashed application, but Chromium and
# Electron child processes (--type=renderer, gpu-process, ...) crash and are
# restarted by their parent while the app keeps working, so they are not worth
# a critical toast (#16819).

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/bin"
NOTIFY_LOG="$TMPDIR/notify-log"

cat >"$TMPDIR/bin/journalctl" <<SH
#!/bin/bash
# The script follows the journal; a single canned entry then EOF ends it.
cat "$TMPDIR/entry.json"
SH

cat >"$TMPDIR/bin/omarchy-notification-wait" <<'SH'
#!/bin/bash
exit 0
SH

cat >"$TMPDIR/bin/omarchy-notification-send" <<SH
#!/bin/bash
printf 'NOTIFY %s\n' "\$*" >>"$NOTIFY_LOG"
SH

cat >"$TMPDIR/bin/omarchy-default-agent" <<'SH'
#!/bin/bash
echo claude
SH

cat >"$TMPDIR/bin/omarchy-toggle-enabled" <<'SH'
#!/bin/bash
exit 1
SH

cat >"$TMPDIR/bin/omarchy-i18n" <<'SH'
#!/bin/bash
printf '%s ' "$@"
SH

chmod +x "$TMPDIR/bin/"*

entry() {
  local uid=$1 comm=$2 cmdline=$3
  # Cmdline pieces separated by | become NUL-separated in the JSON, the way
  # the journal stores a cmdline.
  jq -cn --arg uid "$uid" --arg comm "$comm" --arg cmdline "$cmdline" '{
    "_UID": $uid,
    "COREDUMP_COMM": $comm,
    "COREDUMP_PID": "1234",
    "COREDUMP_EXE": "/opt/spotify/spotify",
    "COREDUMP_SIGNAL_NAME": "SIGSEGV",
    "COREDUMP_CMDLINE": ($cmdline | split("|") | join("\u0000"))
  }'
}

run_watch() {
  PATH="$TMPDIR/bin:$ROOT/bin:$PATH" timeout 20 bash "$ROOT/bin/omarchy-crash-watch"
}

notifications() {
  [[ -f $NOTIFY_LOG ]] && cat "$NOTIFY_LOG" || true
}

# A child process of a Chromium/Electron app is announced without the fix, so
# this is the red test: the toast must stay silent.
entry "$UID" spotify $'/opt/spotify/spotify --type=gpu-process --no-sandbox' >"$TMPDIR/entry.json"
rm -f "$NOTIFY_LOG"
run_watch >/dev/null 2>&1
if [[ $(notifications) == *NOTIFY* ]]; then
  fail "a recovered Chromium child process (--type=) is not announced" "$(notifications)"
fi
pass "a recovered Chromium child process (--type=) is not announced"

# The cmdline is NUL-separated in the journal, so the guard must survive the
# NULs being turned into separators rather than glued into one word.
entry "$UID" spotify '/opt/spotify/spotify|--type=renderer|--no-sandbox' >"$TMPDIR/entry.json"
rm -f "$NOTIFY_LOG"
run_watch >/dev/null 2>&1
if [[ $(notifications) == *NOTIFY* ]]; then
  fail "a child process with NUL-separated cmdline fields is not announced" "$(notifications)"
fi
pass "a child process with NUL-separated cmdline fields is not announced"

# The main process crashing is exactly what the toast is for: no --type= flag.
entry "$UID" spotify '/opt/spotify/spotify --no-sandbox --ozone-platform=x11' >"$TMPDIR/entry.json"
rm -f "$NOTIFY_LOG"
run_watch >/dev/null 2>&1
if [[ $(notifications) != *NOTIFY* ]]; then
  fail "a crash of the main process is still announced"
fi
pass "a crash of the main process is still announced"

# Another user's crash stays a sysadmin's problem, child or not.
entry "$((UID + 1))" spotify '/opt/spotify/spotify --type=gpu-process' >"$TMPDIR/entry.json"
rm -f "$NOTIFY_LOG"
run_watch >/dev/null 2>&1
if [[ $(notifications) == *NOTIFY* ]]; then
  fail "another user's crash is not announced"
fi
pass "another user's crash is not announced"
