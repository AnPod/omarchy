#!/bin/bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

conf="$ROOT/default/UPower/UPower.conf.d/70-omarchy-critical-hibernate.conf"
[[ -f $conf ]] || fail "UPower critical-hibernate drop-in is missing"
grep -q '^CriticalPowerAction=Hibernate$' "$conf" ||
  fail "drop-in sets CriticalPowerAction=Hibernate"
grep -q '70-omarchy-critical-hibernate' "$ROOT/bin/omarchy-hibernation-setup" ||
  fail "hibernation-setup installs the UPower drop-in"
grep -q '70-omarchy-critical-hibernate' "$ROOT/bin/omarchy-hibernation-remove" ||
  fail "hibernation-remove clears the UPower drop-in"
grep -q '70-omarchy-critical-hibernate' "$ROOT/migrations/1790543200.sh" ||
  fail "migration installs the UPower drop-in for existing hibernation setups"
pass "critical battery hibernates when Omarchy hibernation is configured"
