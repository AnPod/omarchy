#!/bin/bash

set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"
require_command jq

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/cache"
export MET_CALLS="$work/calls" MET_HEADERS="$work/request-headers"
marker="$work/executed"
printf -v attack '$(touch %s)' "$marker"
export TEST_LAST_MODIFIED="$attack"
cat >"$work/bin/curl" <<'SH'
#!/bin/bash
set -euo pipefail
printf 'request\n' >>"$MET_CALLS"
while (( $# )); do
  case "$1" in
    -D) headers=$2; shift 2 ;;
    -o) body=$2; shift 2 ;;
    -H) printf '%s\n' "$2" >>"$MET_HEADERS"; shift 2 ;;
    *) shift ;;
  esac
done
printf 'HTTP/1.1 %s\r\nLast-Modified: %s\r\n\r\n' "${TEST_HTTP_CODE:-200}" "$TEST_LAST_MODIFIED" >"$headers"
if [[ -n ${TEST_BODY_FILE:-} ]]; then
  cp "$TEST_BODY_FILE" "$body"
else
  printf '{"type":"Feature","properties":{"timeseries":[{"time":"2026-10-14T00:00:00Z","data":{"instant":{"details":{"air_temperature":12}}}}]}}\n' >"$body"
fi
printf '%s' "${TEST_HTTP_CODE:-200}"
SH
chmod +x "$work/bin/curl"

fetch() {
  PATH="$work/bin:$PATH" "$ROOT/shell/plugins/panels/weather/met-fetch.sh" 46.05 14.51 "$work/cache"
}
requests() {
  wc -l <"$MET_CALLS"
}

fetch >"$work/output"
fetch >"$work/output"
[[ ! -e $marker ]] || fail "remote Last-Modified must never execute when metadata is read"
[[ $(requests) == 1 ]] || fail "a fresh cache must avoid another request"
[[ $(jq -r .last_modified "$work/cache/meta") == "$attack" ]] || fail "remote header must round-trip as JSON data"
[[ $(jq -r .status "$work/output") == "throttled" ]] || fail "fresh metadata retains throttling"
pass "remote command substitutions stay inert across cache reads"

# Revalidation must send the stored header literally, not evaluate it.
jq '.last_fetch = "0"' "$work/cache/meta" >"$work/meta"
mv "$work/meta" "$work/cache/meta"
cp "$work/cache/body.json" "$work/original-body"
TEST_HTTP_CODE=304 fetch >"$work/output"
[[ $(requests) == 2 ]] || fail "stale cache makes one revalidation request"
grep -Fx "If-Modified-Since: $attack" "$MET_HEADERS" >/dev/null || fail "revalidation sends the literal cached header"
cmp -s "$work/original-body" "$work/cache/body.json" || fail "304 preserves the cached body"
[[ ! -e $marker ]] || fail "revalidation must not execute the header"
[[ $(jq -r .status "$work/output") == "not-modified" ]] || fail "304 reports not-modified"
fetch >"$work/output"
[[ $(requests) == 2 ]] || fail "304 metadata retains throttling"
pass "304 revalidation preserves data and backs off without executing headers"

expires=$(( $(date +%s) + 3600 ))
jq --arg expires "$expires" '.last_fetch = "0" | .expires = $expires' "$work/cache/meta" >"$work/meta"
mv "$work/meta" "$work/cache/meta"
fetch >"$work/output"
[[ $(requests) == 2 && $(jq -r .status "$work/output") == "fresh" ]] || fail "JSON metadata preserves Expires handling"
pass "unexpired JSON metadata serves the cache without a request"

# Treat timestamps as validated data before they reach Bash arithmetic.
for field in last_fetch expires; do
  for invalid in "$attack" '1+2' '-1' '08' '0xFF' '9999999999999999999999999999'; do
    before=$(requests)
    jq --arg field "$field" --arg invalid "$invalid" '.[$field] = $invalid' "$work/cache/meta" >"$work/meta"
    mv "$work/meta" "$work/cache/meta"
    fetch >"$work/output"
    [[ ! -e $marker ]] || fail "invalid $field must not execute as arithmetic"
    [[ $(requests) == $((before + 1)) ]] || fail "invalid $field metadata is ignored and refreshed"
  done
done
pass "malformed timestamps are ignored before arithmetic or throttling"

# An old executable metadata file is never sourced, including on upgrades.
printf 'touch %q\n' "$marker" >"$work/cache/meta"
before=$(requests)
fetch >"$work/output"
[[ ! -e $marker && $(requests) == $((before + 1)) ]] || fail "legacy shell metadata must be ignored"
jq -e '.meta_lat == "46.0500" and .meta_lon == "14.5100"' "$work/cache/meta" >/dev/null || fail "legacy metadata is replaced by JSON"
pass "legacy shell metadata is refreshed without execution"

# A bad HTTP 200 must not discard the forecast or postpone recovery.
jq '.last_fetch = "0" | .expires = ""' "$work/cache/meta" >"$work/meta"
mv "$work/meta" "$work/cache/meta"
cp "$work/cache/meta" "$work/original-meta"
cp "$work/cache/body.json" "$work/original-body"
cp "$work/cache/headers.txt" "$work/original-headers"
for invalid in '' '<html>upstream error</html>' '{' 'null' '{}' \
  '{"type":"Feature","properties":{"timeseries":[]}}' \
  '{"type":"Feature","properties":{"timeseries":{}}}' \
  '{"type":"Feature","properties":{"timeseries":[null]}}' \
  '{"type":"Feature","properties":{"timeseries":[{"time":7,"data":{}}]}}' \
  "$(cat "$work/original-body") {}"; do
  printf '%s' "$invalid" >"$work/response"
  before=$(requests)
  if TEST_BODY_FILE="$work/response" fetch >"$work/output"; then
    fail "invalid HTTP 200 must fail instead of replacing the cache"
  fi
  [[ $(requests) == $((before + 1)) ]] || fail "invalid response must not throttle the next attempt"
  jq -e '.status == "error" and .cached == true and .reason == "invalid forecast"' "$work/output" >/dev/null || fail "invalid response reports cached fallback"
  for file in body.json meta headers.txt; do
    case "$file" in
      body.json) original=original-body ;;
      meta) original=original-meta ;;
      headers.txt) original=original-headers ;;
    esac
    cmp -s "$work/$original" "$work/cache/$file" || fail "invalid response must preserve $file"
  done
  [[ ! -e $work/cache/body.json.tmp && ! -e $work/cache/headers.txt.tmp ]] || fail "invalid response cleans temporary files"
done
pass "invalid HTTP 200 responses preserve the complete cache and allow recovery"

before=$(requests)
fetch >"$work/output"
[[ $(requests) == $((before + 1)) ]] || fail "valid response immediately recovers after rejection"
jq -e '.status == "ok"' "$work/output" >/dev/null || fail "valid forecast is accepted"
fetch >"$work/output"
[[ $(requests) == $((before + 1)) ]] || fail "successful recovery restores throttling"
pass "valid forecast recovers immediately and restores normal backoff"

rm -f "$work/cache/body.json" "$work/cache/meta" "$work/cache/headers.txt"
printf 'not JSON' >"$work/response"
if TEST_BODY_FILE="$work/response" fetch >"$work/output"; then
  fail "invalid first response must fail"
fi
jq -e '.status == "error" and .cached == false' "$work/output" >/dev/null || fail "invalid first response reports no cached fallback"
[[ ! -e $work/cache/body.json && ! -e $work/cache/meta && ! -e $work/cache/headers.txt ]] || fail "invalid first response creates no cache"
pass "invalid first response leaves no forecast or throttle metadata"
