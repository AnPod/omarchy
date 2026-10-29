#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_quickshell "lock IME preedit test"

# Password fields must hide the IME preedit: echoMode only masks committed
# text, so with fcitx5/mozc active the lock and polkit surfaces drew the
# composing password in plaintext (#16976).
run_qml_fixture lock-ime-preedit "password fields hide the IME preedit" Ui Commons

# PolkitAgent registers a real PolicyKit listener, so it cannot be
# instantiated in a fixture; assert on its password input's declared hints
# instead, scoped to the `id: passwordInput` object block.
run_node_test <<'JS'
const fs = require('fs')
const src = fs.readFileSync(path.join(root, 'shell/plugins/polkit/PolkitAgent.qml'), 'utf8')

// Balanced-brace slice of the object block that opens at `start` (index of
// the opening brace).
function blockOf(src, start) {
  let depth = 0
  for (let i = start; i < src.length; i++) {
    if (src[i] === '{') depth++
    else if (src[i] === '}') {
      depth--
      if (depth === 0) return src.slice(start, i + 1)
    }
  }
  return ''
}

const anchor = src.indexOf('id: passwordInput')
assert(anchor !== -1, 'PolkitAgent still has a passwordInput field')
const open = src.lastIndexOf('TextInput', anchor)
assert(open !== -1, 'passwordInput is a TextInput')
const block = blockOf(src, open)
assert(block.includes('echoMode'), 'passwordInput block parsed (echoMode found)')
assert(/ImhHiddenText/.test(block), 'polkit password input hides the IME preedit')
assert(/ImhSensitiveData/.test(block), 'polkit password input marks data sensitive')
assert(/ImhNoPredictiveText/.test(block), 'polkit password input disables predictive text')
JS
