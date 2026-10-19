#!/bin/bash

# A direct summon (`omarchy menu summon <alias>`) must not run an action row or
# open a submenu that the menu's `when` guards have hidden. #15742

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

run_node_test <<'JS'
const fs = require('fs')
const menu = requireFromRoot('shell/plugins/menu/MenuModel.js')
const menuQml = fs.readFileSync(path.join(root, 'shell/plugins/menu/Menu.qml'), 'utf8')

const items = {
  root: menu.normalizeItem('root', { label: 'Go' }),
  style: menu.normalizeItem('style', { label: 'Style' }),
  'style.theme': menu.normalizeItem('style.theme', { label: 'Themes', aliases: 'theme', action: 'omarchy-theme-set' }),
  'record.stop': menu.normalizeItem('record.stop', { label: 'Stop recording', aliases: 'screenrecord-stop', when: 'recording-active', action: 'omarchy-screenrecord-stop' }),
  vm: menu.normalizeItem('vm', { label: 'Virtualization', when: 'has-vm' }),
  'vm.apps': menu.normalizeItem('vm.apps', { label: 'Apps', action: 'list-vms' }),
  'jump': menu.normalizeItem('jump', { label: 'Jump', target: 'style' }),
  'jump.hidden': menu.normalizeItem('jump.hidden', { label: 'Hidden jump', target: 'vm', when: 'recording-active' })
}
const order = Object.keys(items)

assertEqual(
  menu.routeTarget(items, order, { 'record.stop': false }, 'screenrecord-stop'),
  null,
  'summon refuses an action its when guard hid'
)
assertEqual(
  menu.routeTarget(items, order, { 'record.stop': true }, 'screenrecord-stop'),
  'record.stop',
  'summon runs the same action when its when guard allows it'
)
assertEqual(
  menu.routeTarget(items, order, { vm: false }, 'vm'),
  null,
  'summon refuses a submenu its when guard hid'
)
assertEqual(
  menu.routeTarget(items, order, { vm: true }, 'vm'),
  'vm',
  'summon opens the same submenu when its when guard allows it'
)
assertEqual(
  menu.routeTarget(items, order, { 'jump.hidden': false }, 'jump.hidden'),
  null,
  'summon refuses a hidden link'
)
assertEqual(
  menu.routeTarget(items, order, { 'jump.hidden': true }, 'jump.hidden'),
  'jump.hidden',
  'summon follows a link its when guard allows'
)
assertEqual(
  menu.routeTarget(items, order, {}, 'screenrecord-stop'),
  'record.stop',
  'summon still runs before the when guards have evaluated'
)
assertEqual(
  menu.routeTarget(items, order, {}, 'theme'),
  'style.theme',
  'summon keeps resolving a visible alias'
)
assertEqual(
  menu.routeTarget(items, order, {}, 'nope'),
  'nope',
  'summon keeps the unknown-id fallthrough'
)
assertEqual(
  menu.routeTarget(items, order, {}, ''),
  'root',
  'summon keeps opening root for an empty route'
)

assert(
  /function openRoute\(initialMenu\) \{[\s\S]*?MenuModel\.routeTarget\(root\.items, root\.itemOrder, root\.whenResults, initialMenu\)[\s\S]*?return "hidden"/.test(menuQml),
  'openRoute routes through the when-guard check before running or opening'
)
assert(
  !/function openRoute\(initialMenu\) \{[\s\S]*?root\.resolveRoute\(initialMenu\)/.test(menuQml),
  'openRoute no longer resolves past the visibility check'
)
JS
