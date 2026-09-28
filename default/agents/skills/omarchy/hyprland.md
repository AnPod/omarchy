# Hyprland Configuration

Read this before changing keybindings, monitors, window rules, or any other
Hyprland (window manager) configuration.

Omarchy configures Hyprland in Lua. User files are loaded after Omarchy's
defaults, so overrides go here:

```
~/.config/hypr/
├── hyprland.lua       # Main config (loads Omarchy defaults, then user files)
├── bindings.lua       # Keybindings
├── monitors.lua       # Display configuration
├── input.lua          # Keyboard/mouse settings
├── looknfeel.lua      # Appearance (gaps, borders, animations)
├── autostart.lua      # Startup applications
├── hyprsunset.conf    # Night light / blue light filter
└── xdph.conf          # Screen sharing / desktop portal
```

**Key behaviors (the `.lua` files):**
- Hyprland auto-reloads on config save (no restart needed for most changes)
- Use `hyprctl reload` to force reload
- After ANY Hyprland Lua config change, validate with `hyprctl reload` followed by `hyprctl configerrors`
- If `hyprctl configerrors` reports errors, address them and rerun validation until clean or until a real blocker is identified
- Use `omarchy refresh hyprland` to reset the Lua config files to defaults

The two `.conf` files are read by separate processes, so `hyprctl` neither
applies nor validates them:
- `hyprsunset.conf` (night light): apply changes with `omarchy restart hyprsunset`; reset with `omarchy refresh hyprsunset`
- `xdph.conf` (screen-sharing portal): applies when the portal restarts, e.g. on next login

## Keybindings

Edit `~/.config/hypr/bindings.lua`. Format:
```lua
o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")
o.bind("SUPER + B", "Browser", { launch = "chromium" })  -- launch wraps with uwsm-app
o.bind("SUPER + M", "Theme menu", { menu = "theme" })     -- toggle an Omarchy menu route
o.bind("SUPER + N", "Network", { panel = "omarchy.network" })  -- toggle a shell panel
```

Prefer `{ menu = ... }` and `{ panel = ... }` over running `omarchy-menu toggle ...` or `omarchy-shell shell toggle ...` as a command. Routes and panels listed in `$OMARCHY_PATH/default/omarchy/shortcuts` go straight to the running shell as Hyprland global shortcuts, with no process started on each press; any other route or panel still works, through the command.

View current bindings: `omarchy menu keybindings --print`

**IMPORTANT: When re-binding an existing key:**

1. First check existing bindings: `omarchy menu keybindings --print`
2. If the key is already bound, use `o.rebind(...)` to remove the existing binding and add its replacement. It takes the same arguments as `o.bind(...)`.
3. Inform the user what the key was previously bound to

Example - rebinding SUPER+F (which is bound to fullscreen by default):
```lua
-- Replace SUPER+F (was: fullscreen) with the file manager.
o.rebind("SUPER + F", "File manager", { launch = "nautilus" })
```

Tell the user which action was replaced. Use `hl.unbind(...)` to remove a binding without replacing it.

## Display/Monitors

Edit `~/.config/hypr/monitors.lua`. Format:
```lua
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "1920x0", scale = 1 })
```

List monitors and supported modes: `hyprctl monitors all`

## Window Rules

**CRITICAL: Hyprland window rules syntax changes frequently between versions.**

Before writing ANY window rules, you MUST fetch the current documentation from the official Hyprland wiki:
- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

DO NOT rely on cached or memorized window rule syntax. The format has changed multiple times and using outdated syntax will cause errors or unexpected behavior.

Window rules go in `~/.config/hypr/hyprland.lua` or a required Lua module. Prefer Omarchy's `o.window(match, rules)` helper — see examples in `$OMARCHY_PATH/default/hypr/windows.lua`.

## Window close vs. app termination

On Hyprland 0.56+, [`hl.dsp.window.close()`](https://github.com/hyprwm/Hyprland/blob/main/docs/hyprctl.1.rst) is the window-close dispatcher. From a terminal, ask Hyprland to close the focused window with:

```bash
hyprctl dispatch "hl.dsp.window.close()"
```

A close request is not the same as force-terminating the application. An app may remain running if it has another window or background work.

By default, SUPER+W and SUPER+Q are each explicitly bound to `hl.dsp.window.close()`, so either shortcut closes the focused window. Rebinding one shortcut affects only that shortcut; it does not change the other shortcut, the title-bar X button, or every other close action. To keep both shortcuts using the window-close action, configure each one explicitly.

For Keet installed from Flathub, inspect the focused window class using Hyprland's [`repl`](https://wiki.hypr.land/Configuring/Advanced-and-Cool/Using-hyprctl/):

```bash
hyprctl repl 'hl.get_active_window().class'
```

The returned Hyprland class is used for window matching and is not necessarily the Flatpak application ID. Keet's [Flathub application ID](https://flathub.org/en/apps/io.keet.Keet) is `io.keet.Keet`.

First close the focused Keet window normally:

```bash
hyprctl dispatch "hl.dsp.window.close()"
```

If Keet remains running afterward and you deliberately want to stop its Flatpak app instance, run:

```bash
flatpak kill io.keet.Keet
```

This may also close Keet's other windows. Keep the ordinary Hyprland close behavior for other apps.

### Optional: force-stop Keet from SUPER+W

To deliberately make SUPER+W force-stop Keet after requesting the normal window close, first focus Keet and run `hyprctl repl 'hl.get_active_window().class'`. Copy the exact returned class into `KEET_CLASS` below; do not assume it matches the Flatpak application ID.

Create the script directory, then create `~/.config/hypr/scripts/close-window`:

```bash
mkdir -p "$HOME/.config/hypr/scripts"
```

```bash
#!/bin/bash

KEET_CLASS=""
window_class=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty' 2>/dev/null) || window_class=""

hyprctl dispatch "hl.dsp.window.close()" || exit 1

if [[ -n "$KEET_CLASS" && -n "$window_class" && "$window_class" == "$KEET_CLASS" ]]; then
  flatpak kill io.keet.Keet
fi
```

Set `KEET_CLASS` to the class you captured, then make the script executable:

```bash
chmod +x "$HOME/.config/hypr/scripts/close-window"
```

In `~/.config/hypr/bindings.lua`, replace only the default SUPER+W binding with the script's direct path:

```lua
o.rebind("SUPER + W", "Close window", os.getenv("HOME") .. "/.config/hypr/scripts/close-window")
```

The script captures the focused window's class before asking Hyprland to close it. A failed or empty class query cannot trigger `flatpak kill`; every class other than the explicitly configured Keet class gets only the ordinary window close. For a matching Keet window, pressing SUPER+W force-stops the `io.keet.Keet` Flatpak instance after the close request and may close its other windows too. SUPER+Q keeps its default ordinary close behavior unless separately rebound, and the title-bar X is unaffected.

Validate the Lua binding after saving:

```bash
hyprctl reload
hyprctl configerrors
```

To restore the default SUPER+W close, remove this `o.rebind("SUPER + W", ...)` line from `~/.config/hypr/bindings.lua`, then run `hyprctl reload` and `hyprctl configerrors` again.
