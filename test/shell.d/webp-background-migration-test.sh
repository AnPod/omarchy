#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
home="$test_dir/home"
migration="$ROOT/migrations/1791470456.sh"

reset_home() {
  rm -rf "$home"
  mkdir -p "$home/.local/state/omarchy/current/theme/backgrounds" "$home/.local/state/omarchy/theme-backgrounds"
}

run_migration() {
  HOME="$home" OMARCHY_PATH="$ROOT" bash -euo pipefail "$migration" >"$test_dir/output"
}

backgrounds="$home/.local/state/omarchy/current/theme/backgrounds"
current="$home/.local/state/omarchy/current/background"
remembered="$home/.local/state/omarchy/theme-backgrounds/tokyo-night"
remembered_png="$home/.local/state/omarchy/theme-backgrounds/catppuccin"

reset_home
touch "$backgrounds/current.webp"
ln -s "$backgrounds/current.jpg" "$current"
printf '%s\n' "$backgrounds/2-swirl-buck.jpg" >"$remembered"
printf '%s\n' "$backgrounds/omarchy.png" >"$remembered_png"
run_migration
[[ $(readlink "$current") == "$backgrounds/current.webp" ]] || fail "the current background moves from the removed JPEG to its WebP replacement"
[[ $(<"$remembered") == "$backgrounds/2-swirl-buck.webp" ]] || fail "an inactive theme's remembered JPEG moves to its bundled WebP replacement"
[[ $(<"$remembered_png") == "$backgrounds/omarchy.webp" ]] || fail "an inactive theme's remembered PNG moves to its bundled WebP replacement"
pass "converted bundled backgrounds keep their current and remembered selections"

run_migration
[[ $(readlink "$current") == "$backgrounds/current.webp" ]] || fail "the repair can be rerun"
[[ $(<"$remembered") == "$backgrounds/2-swirl-buck.webp" ]] || fail "the remembered JPEG repair can be rerun"
[[ $(<"$remembered_png") == "$backgrounds/omarchy.webp" ]] || fail "the remembered PNG repair can be rerun"
pass "the background repair is idempotent"

reset_home
touch "$backgrounds/kept.jpg" "$backgrounds/kept.webp"
ln -s "$backgrounds/kept.jpg" "$current"
printf '%s\n' "$backgrounds/kept.jpg" >"$remembered"
run_migration
[[ $(readlink "$current") == "$backgrounds/kept.jpg" ]] || fail "an existing JPEG background is preserved"
[[ $(<"$remembered") == "$backgrounds/kept.jpg" ]] || fail "an existing remembered JPEG is preserved"
pass "existing backgrounds are not replaced just because a WebP shares their stem"

reset_home
ln -s "$backgrounds/missing.jpeg" "$current"
printf '%s\n' "$backgrounds/missing.png" >"$remembered"
run_migration
[[ $(readlink "$current") == "$backgrounds/missing.jpeg" ]] || fail "a dangling selection without an exact WebP replacement is preserved"
[[ $(<"$remembered") == "$backgrounds/missing.png" ]] || fail "a dangling remembered selection without an exact WebP replacement is preserved"
pass "unrelated dangling background paths are left alone"
