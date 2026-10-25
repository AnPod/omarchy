#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

# The panel plugin Loader's onStatusChanged handler must look its error detail
# up through the Loader itself (panelLoader), not unscoped identifiers, so a
# failed plugin load reports the real QML error instead of throwing a
# ReferenceError that replaces it in the journal.
run_node_test <<'JS'
const fs = require('fs')
const qml = fs.readFileSync(root + '/shell/shell.qml', 'utf8')

const loaderBlock = qml.match(/property Loader panelLoader: Loader \{([\s\S]*?)\n      \}/)
assert(loaderBlock, 'shell.qml still declares the panelLoader Loader')
const statusBlock = loaderBlock[1].match(/onStatusChanged: \{([\s\S]*)\}/)
assert(statusBlock, 'panelLoader has an onStatusChanged handler')
const body = statusBlock[1]

const warns = []
const hides = []
const fakeConsole = { warn: (...parts) => warns.push(parts.join(' ')) }
const shell = { hide: (id) => hides.push(id) }
const panelEntry = { pluginId: 'test.broken-panel' }
const DETAIL = 'qs:///plugin/Main.qml:5 module "somemodule" is not installed'
const Loader = { Error: 4 }

function runHandler(statusValue, loaderMock) {
  warns.length = 0
  hides.length = 0
  const handler = new Function(
    'status', 'Loader', 'shell', 'panelEntry', 'panelLoader', 'console', body)
  handler(4, Loader, shell, panelEntry, loaderMock, fakeConsole)
}

// errorString() carries the real cause; sourceComponent is null on a failed
// source load.
runHandler(4, { errorString: () => DETAIL, sourceComponent: null })
assert(warns.length === 1, 'one warn per failed panel load', JSON.stringify(warns))
assert(warns[0].includes('test.broken-panel'), 'warn names the failing plugin id', warns[0])
assert(warns[0].includes(DETAIL), 'warn carries the real Loader error, not a ReferenceError', warns[0])
assert(hides.join(',') === 'test.broken-panel', 'the broken panel is hidden after the report', hides.join(','))

// Fallback: when the Loader has no string of its own, read it off the
// loaded Component.
runHandler(4, { errorString: () => '', sourceComponent: { errorString: () => 'comp detail' } })
assert(warns.length === 1 && warns[0].includes('comp detail'),
  'falls back to the sourceComponent error string', warns.join('\n'))
JS
