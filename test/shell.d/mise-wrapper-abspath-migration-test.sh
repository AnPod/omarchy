#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
bin_dir="$tmpdir/home/.local/bin"
mkdir -p "$bin_dir" "$tmpdir/bin"

cat >"$tmpdir/bin/omarchy-mise-install" <<'SH'
#!/bin/bash
# Record regenerations; write a marker so the migration can be re-run safely.
printf 'regenerate %s %s %s\n' "$1" "$2" "$3" >>"$REGEN_LOG"
printf '#!/bin/bash\nexport MISE_MINIMUM_RELEASE_AGE=0\nmise use -g --quiet "%s" || exit 1\nbin_path=$(mise which --tool "%s" %s) || exit 1\nexec mise x "%s" -- "$bin_path" "$@"\n' \
  "$1" "$1" "$3" "$1" >"$HOME/.local/bin/$2"
chmod +x "$HOME/.local/bin/$2"
SH
chmod +x "$tmpdir/bin/omarchy-mise-install"

write_stale() {
  local name=$1 package=$2 bin=$3
  printf '#!/bin/bash\nexport MISE_MINIMUM_RELEASE_AGE=0\nmise use -g --quiet "%s" || exit 1\nexec mise x "%s" -- "%s" "$@"\n' \
    "$package" "$package" "$bin" >"$bin_dir/$name"
  chmod +x "$bin_dir/$name"
}

write_stale omp github:can1357/oh-my-pi omp
write_stale already-new github:can1357/oh-my-pi omp
# Make already-new look like the new template so migration skips it.
printf '#!/bin/bash\nexport MISE_MINIMUM_RELEASE_AGE=0\nmise use -g --quiet "github:can1357/oh-my-pi" || exit 1\nbin_path=$(mise which --tool "github:can1357/oh-my-pi" omp) || exit 1\nexec mise x "github:can1357/oh-my-pi" -- "$bin_path" "$@"\n' \
  >"$bin_dir/already-new"

REGEN_LOG="$tmpdir/regen.log"
: >"$REGEN_LOG"
migration=$(rg -l 'mise which --tool' "$ROOT/migrations" | head -1)
[[ -n $migration ]] || fail "abspath migration exists"

HOME="$tmpdir/home" PATH="$tmpdir/bin:$PATH" REGEN_LOG="$REGEN_LOG" bash "$migration"

grep -qx 'regenerate github:can1357/oh-my-pi omp omp' "$REGEN_LOG" ||
  fail "migration regenerates bare-name wrappers" "$(cat "$REGEN_LOG")"
grep -q 'already-new' "$REGEN_LOG" &&
  fail "migration leaves already-absolute wrappers alone" "$(cat "$REGEN_LOG")"
grep -q 'bin_path=$(mise which --tool' "$bin_dir/omp" ||
  fail "regenerated wrapper resolves an absolute path"
pass "mise abspath migration regenerates bare-name wrappers only"
