#!/bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

helper="$ROOT/install/helpers/codex-config.sh"
migration="$ROOT/migrations/1790543192.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

home="$test_dir/home"
mkdir -p "$home"
export HOME="$home"
export OMARCHY_PATH="$ROOT"
# shellcheck disable=SC1090
source "$helper"

omarchy_ensure_codex_auto_review_config

config="$home/.codex/config.toml"
[[ -f $config ]] || fail "helper creates ~/.codex/config.toml"
grep -qE '^approvals_reviewer[[:space:]]*=[[:space:]]*"auto_review"$' "$config" ||
  fail "helper seeds approvals_reviewer=auto_review"
grep -qE '^approval_policy[[:space:]]*=[[:space:]]*"on-request"$' "$config" ||
  fail "helper seeds approval_policy=on-request"
grep -qE '^sandbox_mode[[:space:]]*=[[:space:]]*"workspace-write"$' "$config" ||
  fail "helper seeds sandbox_mode=workspace-write"
pass "helper seeds Approve-for-me defaults into an empty Codex config"

# Second run must be a no-op: do not duplicate keys or rewrite user values.
before=$(cat "$config")
omarchy_ensure_codex_auto_review_config
[[ $(cat "$config") == "$before" ]] || fail "helper is idempotent on a complete config"
pass "helper is idempotent on a complete config"

# Existing keys win; only missing Approve-for-me keys are appended.
custom_home="$test_dir/custom"
mkdir -p "$custom_home/.codex"
export HOME="$custom_home"
cat >"$custom_home/.codex/config.toml" <<'EOF'
model = "gpt-5"
approvals_reviewer = "user"
EOF
omarchy_ensure_codex_auto_review_config
grep -qE '^approvals_reviewer[[:space:]]*=[[:space:]]*"user"$' "$custom_home/.codex/config.toml" ||
  fail "helper preserves an existing approvals_reviewer"
grep -qE '^approvals_reviewer[[:space:]]*=[[:space:]]*"auto_review"$' "$custom_home/.codex/config.toml" &&
  fail "helper must not add auto_review when approvals_reviewer is already set"
grep -qE '^approval_policy[[:space:]]*=[[:space:]]*"on-request"$' "$custom_home/.codex/config.toml" ||
  fail "helper fills a missing approval_policy"
grep -qE '^sandbox_mode[[:space:]]*=[[:space:]]*"workspace-write"$' "$custom_home/.codex/config.toml" ||
  fail "helper fills a missing sandbox_mode"
grep -qE '^model[[:space:]]*=[[:space:]]*"gpt-5"$' "$custom_home/.codex/config.toml" ||
  fail "helper preserves unrelated Codex config"
pass "helper preserves existing keys and fills only the missing ones"

# Migration sources the helper the same way update does for existing installs.
migration_home="$test_dir/migration"
mkdir -p "$migration_home"
HOME="$migration_home" OMARCHY_PATH="$ROOT" bash -euo pipefail "$migration" >/dev/null
grep -qE '^approvals_reviewer[[:space:]]*=[[:space:]]*"auto_review"$' "$migration_home/.codex/config.toml" ||
  fail "migration seeds approvals_reviewer via the shared helper"
pass "migration seeds Codex auto-review config for existing installs"

# Launchers must not pass --approve-for-me (CLI overrides force embedded mode).
grep -Fq "alias cy='codex'" "$ROOT/default/bash/aliases" ||
  fail "cy alias launches plain codex"
grep -qE "alias cy=.*approve-for-me" "$ROOT/default/bash/aliases" &&
  fail "cy alias must not pass --approve-for-me"
grep -qE 'command=\(codex --approve-for-me\)' "$ROOT/bin/omarchy-agent" &&
  fail "omarchy-agent must not pass --approve-for-me"
pass "launchers avoid --approve-for-me so Codex can use the shared server"
