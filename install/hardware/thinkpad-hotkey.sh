# Widen thinkpad_acpi hotkey_mask so F10 (Bluetooth) and similar keys emit events.
if [[ -d /sys/module/thinkpad_acpi ]]; then
  install -Dm644 "$OMARCHY_PATH/default/modprobe.d/omarchy-thinkpad-hotkey.conf" \
    /etc/modprobe.d/omarchy-thinkpad-hotkey.conf
  if [[ -w /sys/devices/platform/thinkpad_acpi/hotkey_mask ]]; then
    echo 0xffffff > /sys/devices/platform/thinkpad_acpi/hotkey_mask || true
  fi
fi
