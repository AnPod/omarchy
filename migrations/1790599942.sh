echo "Keep Intel Bluetooth awake when TLP manages USB power"

src="$OMARCHY_PATH/etc/tlp.d/omarchy-bluetooth-usb.conf"
dst=/etc/tlp.d/omarchy-bluetooth-usb.conf

[[ -f $src ]] || exit 0
[[ -f $dst ]] && exit 0

sudo mkdir -p /etc/tlp.d
sudo install -Dm644 -- "$src" "$dst"

# TLP rereads drop-ins on the next start; restart only when it is already active.
if omarchy-cmd-present systemctl && systemctl is-active --quiet tlp.service; then
  sudo systemctl restart tlp.service >/dev/null 2>&1 || true
fi
