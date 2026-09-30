echo "Restore LIFEBOOK P727 keyboard at disk unlock"

if ! omarchy-hw-fujitsu-lifebook-p727; then
  exit 0
fi

dropin=/etc/limine-entry-tool.d/lifebook-p727-i8042.conf
if [[ ! -f $dropin ]]; then
  sudo mkdir -p /etc/limine-entry-tool.d
  sudo tee "$dropin" >/dev/null <<'DROPIN'
# Built-in keyboard is silent at LUKS unlock while i8042 multiplexing is on
# (#13502). Keep multiplexing off so the AT Translated Set 2 device answers.
KERNEL_CMDLINE[default]+=" i8042.nomux"
DROPIN
fi

if omarchy-cmd-present limine-mkinitcpio; then
  sudo limine-mkinitcpio
fi
