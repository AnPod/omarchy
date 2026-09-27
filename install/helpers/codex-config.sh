# Seed Codex "Approve for me" defaults into config.toml without CLI overrides.
# Codex 0.157+ treats --approve-for-me (and -c/--enable/--disable/--search) as
# configuration overrides that force embedded mode and skip the shared
# background server. Persisting the same keys keeps auto-review and the shared
# server. Existing keys are left alone.

omarchy_ensure_codex_auto_review_config() {
  local codex_home=${CODEX_HOME:-$HOME/.codex}
  local config=$codex_home/config.toml
  local added=false
  local key value

  mkdir -p "$codex_home"
  [[ -f $config ]] || : >"$config"

  for key in approvals_reviewer approval_policy sandbox_mode; do
    case $key in
    approvals_reviewer) value='"auto_review"' ;;
    approval_policy) value='"on-request"' ;;
    sandbox_mode) value='"workspace-write"' ;;
    esac

    if grep -qE "^[[:space:]]*${key}[[:space:]]*=" "$config"; then
      continue
    fi

    if [[ $added == "false" ]]; then
      if [[ -s $config ]]; then
        [[ -z $(tail -c1 "$config") ]] || printf '\n' >>"$config"
        printf '\n' >>"$config"
      fi
      printf '# Omarchy: Approve for me without CLI overrides (keeps the shared background server).\n' >>"$config"
      added=true
    fi

    printf '%s = %s\n' "$key" "$value" >>"$config"
  done
}
