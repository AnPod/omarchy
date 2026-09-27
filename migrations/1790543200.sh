echo "Hibernate on critical battery when Omarchy hibernation is set up"

# Only when the Omarchy resume hook is present — desktops without hibernation
# keep UPower's stock Auto policy.
if [[ -f /etc/mkinitcpio.conf.d/omarchy_resume.conf ]] &&
  grep -q '^HOOKS+=(resume)$' /etc/mkinitcpio.conf.d/omarchy_resume.conf; then
  sudo mkdir -p /etc/UPower/UPower.conf.d
  sudo install -m 0644 -o root -g root -T \
    "$OMARCHY_PATH/default/UPower/UPower.conf.d/70-omarchy-critical-hibernate.conf" \
    /etc/UPower/UPower.conf.d/70-omarchy-critical-hibernate.conf
fi
