echo "Regenerate mise wrappers to stop them recursing through PATH"

restored=0
for wrapper in "$HOME/.local/bin"/*; do
  [[ -f $wrapper && -x $wrapper ]] || continue

  package=$(sed -n 's/^mise use -g "\(.*\)"$/\1/p' "$wrapper")
  bin=$(sed -n 's/^exec "\(.*\)" "\$@"$/\1/p' "$wrapper")

  if [[ -n $package && -n $bin ]]; then
    omarchy-mise-install "$package" "$(basename "$wrapper")" "$bin"
    restored=1
  fi
done

# An empty ~/.local/bin yields no wrappers to parse, so fall back to the
# canonical list in install/user/mise.sh rather than silently leaving the
# documented lazy stubs missing.
if (( ! restored )) && [[ ! -f $HOME/.local/state/omarchy/preinstalls-removed && -f $OMARCHY_PATH/install/user/mise.sh ]]; then
  bash "$OMARCHY_PATH/install/user/mise.sh"
fi
