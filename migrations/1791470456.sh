echo "Repair background selections after bundled images moved to WebP"

replacement_webp() {
  local background="$1"
  local theme="${2:-}"
  local replacement

  [[ ! -e $background ]] || return 1

  case ${background,,} in
  *.jpg | *.jpeg | *.png) replacement="${background%.*}.webp" ;;
  *) return 1 ;;
  esac

  if [[ ! -f $replacement ]]; then
    [[ -n $theme && ${background%/*} == "$HOME/.local/state/omarchy/current/theme/backgrounds" ]] || return 1
    [[ -f $OMARCHY_PATH/themes/$theme/backgrounds/${replacement##*/} ]] || return 1
  fi

  printf '%s\n' "$replacement"
}

current_background="$HOME/.local/state/omarchy/current/background"
if [[ -L $current_background ]]; then
  background=$(readlink "$current_background")
  if replacement=$(replacement_webp "$background"); then
    ln -sfn "$replacement" "$current_background"
  fi
fi

for state_file in "$HOME/.local/state/omarchy/theme-backgrounds/"*; do
  [[ -f $state_file ]] || continue

  background=$(<"$state_file")
  if replacement=$(replacement_webp "$background" "${state_file##*/}"); then
    printf '%s\n' "$replacement" >"$state_file"
  fi
done
