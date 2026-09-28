#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

script="$ROOT/install/hardware/apple/fix-intel-kms.sh"
[[ -f $script ]] || fail "apple intel kms install script exists"
grep -Fq 'MODULES+=(i915)' "$script" || fail "apple intel kms loads i915 early"
grep -Fq 'video=eDP-1:e' "$script" || fail "apple intel kms keeps eDP enabled"
grep -Fq 'fix-intel-kms.sh' "$ROOT/install/hardware/all.sh" ||
  fail "hardware install runs apple intel kms"
pass "apple intel early KMS install is wired"

migration=$(rg -l 'apple-intel-kms.conf' "$ROOT/migrations" | head -1)
[[ -n $migration ]] || fail "migration enables apple intel kms on existing installs"
pass "migration enables apple intel kms on existing installs"
