echo "Seed Codex auto-review in config.toml so cy keeps the shared server"

mkdir -p "$HOME/.codex"
config="$HOME/.codex/config.toml"
if [[ -f $config ]] && grep -q '^approvals_reviewer' "$config"; then
  exit 0
fi
printf '%s\n' 'approvals_reviewer = "auto_review"' >>"$config"
