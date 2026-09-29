echo "Regenerate mise wrappers that exec a bare command name"

# omarchy-mise-install wrappers used to run `exec mise x "<pkg>" -- "<bin>"
# "$@"`, which depends on PATH resolving the bare bin inside mise's sandbox.
# The generator now resolves the tool to an absolute path first
# (`bin_path=$(mise which --tool ...)`) and execs that, so a wrapper keeps
# working when ~/.local/bin precedes mise's shims (#13090). Regenerate every
# wrapper still in the previous form through omarchy-mise-install so the
# template stays in one place.

stale_template() {
  local package=$1 bin=$2

  printf '#!/bin/bash\nexport MISE_MINIMUM_RELEASE_AGE=0\nmise use -g --quiet "%s" || exit 1\nexec mise x "%s" -- "%s" "$@"' "$package" "$package" "$bin"
}

bin_dir="$HOME/.local/bin"

[[ -d $bin_dir ]] || exit 0

for wrapper in "$bin_dir"/*; do
  [[ -f $wrapper && ! -L $wrapper && -r $wrapper ]] || continue

  (($(stat -c%s "$wrapper") <= 1024)) || continue

  contents=$(<"$wrapper")

  package=$(sed -n 's/^mise use -g --quiet "\(.*\)" || exit 1$/\1/p' <<<"$contents")
  bin=$(sed -n 's/^exec mise x ".*" -- "\(.*\)" "\$@"$/\1/p' <<<"$contents")

  [[ -n $package && -n $bin ]] || continue

  [[ $contents == "$(stale_template "$package" "$bin")" ]] || continue

  omarchy-mise-install "$package" "${wrapper##*/}" "$bin"
done
