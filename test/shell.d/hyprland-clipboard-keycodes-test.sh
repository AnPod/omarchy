#!/bin/bash

# Issue #16009: the universal clipboard shortcuts send keysym names ("C", "V",
# "X", "A") to send_key_state, and Hyprland resolves the name against the active
# layout. On a non-Latin layout (us,ru for example) there is no Latin "C"
# keysym, so every press fails with "send_key_state: key not found". The binds
# must send physical keycodes ("code:N") instead, which work under any layout.

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command lua

HOME="$(mktemp -d)" OMARCHY_PATH="$ROOT" lua <<'LUA'
package.path = os.getenv("OMARCHY_PATH") .. "/?.lua;" .. package.path

local sends, binds = {}, {}
hl = setmetatable({
  dsp = setmetatable({}, {
    __index = function(_, name)
      return function(arg) return { dsp = name, arg = arg } end
    end,
  }),
  timer = function(fn, opts)
    fn()
  end,
  dispatch = function(dispatcher)
    table.insert(sends, dispatcher)
  end,
}, {
  __index = function()
    return function() return {} end
  end,
})

local window = { tags = {} }
hl.get_active_window = function()
  return window
end

o = {
  bind = function(keys, description, dispatcher)
    table.insert(binds, { keys = keys, description = description, dispatcher = dispatcher })
  end,
}

require("default.hypr.bindings.clipboard")

local expected = {
  ["Select all"] = { mods = "CTRL", key = "code:38" },
  ["Universal copy"] = { mods = "CTRL", key = "code:54", terminal_mods = "CTRL SHIFT" },
  ["Universal paste"] = { mods = "CTRL", key = "code:55", terminal_mods = "CTRL SHIFT" },
  ["Universal cut"] = { mods = "CTRL", key = "code:53" },
}

local function sends_since(fn)
  local before = #sends
  fn()
  return { table.unpack(sends, before + 1) }
end

local function keys_sent(bind)
  local entries = sends_since(bind.dispatcher)
  local keys = {}
  for _, entry in ipairs(entries) do
    local arg = entry.arg
    table.insert(keys, arg.key .. "@" .. arg.state)
    assert(arg.mods, "every send carries explicit mods")
  end
  return keys, entries
end

local by_description = {}
for _, bind in ipairs(binds) do
  by_description[bind.description] = bind
end

for description, want in pairs(expected) do
  local bind = by_description[description]
  assert(bind, description .. " is bound")

  window.tags = {}
  local keys = keys_sent(bind)
  assert(#keys == 2, description .. " sends a down and an up")
  assert(keys[1] == want.key .. "@down" and keys[2] == want.key .. "@up",
    description .. " sends " .. want.key .. " (got " .. keys[1] .. ", " .. keys[2] .. ")")

  window.tags = { "terminal*" }
  keys = keys_sent(bind)
  assert(#keys == 2, description .. " sends a down and an up to terminals")
  assert(keys[1] == want.key .. "@down" and keys[2] == want.key .. "@up",
    description .. " keeps the same keycode for terminals (got " .. keys[1] .. ", " .. keys[2] .. ")")

  window.tags = {}
  local entries = sends_since(bind.dispatcher)
  assert(entries[1].arg.mods == want.mods, description .. " sends " .. want.mods)
end
LUA

# The keycode strings never regress to layout-resolved keysym names.
if grep -E 'send_shortcut_once\([^)]*"[A-Z]"' "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../default/hypr/bindings/clipboard.lua" >/dev/null; then
  fail "universal clipboard shortcuts send keycodes, not layout-resolved key names"
fi
pass "universal clipboard shortcuts send layout-independent keycodes"
