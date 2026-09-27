echo "Expose ThinkPad Bluetooth F10 hotkey via thinkpad_acpi hotkey_mask"

if [[ -d /sys/module/thinkpad_acpi ]]; then
  sudo install -Dm644 "$OMARCHY_PATH/default/modprobe.d/omarchy-thinkpad-hotkey.conf" \
    /etc/modprobe.d/omarchy-thinkpad-hotkey.conf
  if [[ -w /sys/devices/platform/thinkpad_acpi/hotkey_mask ]]; then
    echo 0xffffff | sudo tee /sys/devices/platform/thinkpad_acpi/hotkey_mask >/dev/null || true
  fi
fi
