#!/bin/bash
#
# The quiet-boot-menu migration authorizes sudo by running a command, not
# sudo -v: under the default verifypw=all, -v asks for a password even when
# every command runs passwordless, which stopped an unattended update in the
# middle of its migrations.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

migration="$ROOT/migrations/1791898365.sh"
test_dir=$(mktemp -d)
trap 'chmod -R u+rwX "$test_dir" 2>/dev/null; rm -rf "$test_dir"' EXIT
stub_bin="$test_dir/bin"
mkdir -p "$stub_bin"

# A sudo that models a passwordless NOPASSWD rule under the default
# verifypw=all: -v still demands a password, while real commands run.
cat >"$stub_bin/sudo" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >>"${SUDO_LOG:?}"
if [[ $1 == -v ]]; then
  echo "sudo: a password is required" >&2
  exit 1
fi
exec "$@"
STUB
chmod +x "$stub_bin/sudo"

run() { # limine conf path
  : >"$test_dir/sudo.log"
  PATH="$stub_bin:$ROOT/bin:$PATH" SUDO_LOG="$test_dir/sudo.log" \
    OMARCHY_LIMINE_CONF="$1" bash -euo pipefail "$migration" >"$test_dir/out" 2>&1
}

sudo_log() { cat "$test_dir/sudo.log"; }

# The reported machine: the ESP is mounted umask=0077, so the menu cannot be
# stat'ed as the user, and sudo -v prompts even though sudo itself is
# passwordless. omarchy-migrate runs a migration with bash -euo pipefail, and
# so does run: the failed authorization used to abort the whole update there.
if (( $(id -u) == 0 )); then
  echo "ok - passwordless sudo authorizes by command and an unreadable menu is left pending, not fatal # SKIP"
else
  mkdir "$test_dir/esp"
  printf 'timeout: 3\n' >"$test_dir/esp/limine.conf"
  chmod 000 "$test_dir/esp"
  run "$test_dir/esp/limine.conf"
  [[ $(sudo_log) != *' -v'* ]] || fail "the migration still authorizes with sudo -v"
  grep -q '^true$' "$test_dir/sudo.log" || fail "the migration did not authorize by running a command"
  grep -q '^test -f' "$test_dir/sudo.log" || fail "the migration did not check the menu through sudo before giving up"
  pass "passwordless sudo authorizes by command and an unreadable menu is left pending, not fatal"
fi

# An unreadable-but-existing menu behind a readable ESP: the migration edits it.
mkdir -p "$test_dir/esp2"
printf '#timeout: 5\n' >"$test_dir/esp2/limine.conf"
run "$test_dir/esp2/limine.conf"
grep -Eq '^timeout: 1$' "$test_dir/esp2/limine.conf" || fail "a readable menu did not get its timeout shortened"
grep -Eq '^quiet: yes$' "$test_dir/esp2/limine.conf" || fail "a readable menu did not get quiet added"
pass "a readable menu still gets timeout: 1 and quiet: yes"
