import QtQuick
import Quickshell
import qs.Commons

ShellRoot {
  id: root

  readonly property string resultPath: Quickshell.env("OMARCHY_QML_TEST_RESULT")
  readonly property string rootPath: Quickshell.env("OMARCHY_PATH")
  property var failures: []

  // Qt.InputMethodHints flags, read from the Qt namespace so the values stay
  // correct across Qt versions.
  readonly property int imhHiddenText: Qt.ImhHiddenText
  readonly property int imhSensitiveData: Qt.ImhSensitiveData
  readonly property int imhNoPredictiveText: Qt.ImhNoPredictiveText

  function fail(message) {
    failures.push(String(message))
  }

  function assertTrue(condition, message) {
    if (!condition) fail(message)
  }

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function writeResult() {
    var payload = JSON.stringify({
      ok: failures.length === 0,
      failures: failures
    })

    if (resultPath) {
      Quickshell.execDetached(["bash", "-lc", "printf '%s' " + shellQuote(payload) + " > " + shellQuote(resultPath)])
    }
  }

  // Collect every object in the tree that exposes echoMode (TextInput and
  // TextField subclasses).
  function collectInputs(obj, acc) {
    if (!obj)
      return acc
    if (obj.echoMode !== undefined)
      acc.push(obj)
    var kids = obj.children || []
    for (var i = 0; i < kids.length; i++)
      collectInputs(kids[i], acc)
    return acc
  }

  Item { id: host; width: 800; height: 600 }

  Timer {
    interval: 1
    running: true
    repeat: false
    onTriggered: {
      try {
        // Lock screen password field: the preedit must be suppressed.
        var lockComponent = Qt.createComponent("file://" + root.rootPath + "/shell/plugins/lock/LockView.qml", Component.PreferSynchronous)
        if (lockComponent.status !== Component.Ready) {
          root.fail("LockView failed to load: " + lockComponent.errorString())
          root.writeResult()
          return
        }
        var lockView = lockComponent.createObject(host, { width: 800, height: 600, loadBackground: false })
        if (!lockView) {
          root.fail("LockView failed to instantiate")
          root.writeResult()
          return
        }
        var lockInputs = root.collectInputs(lockView, [])
        root.assertTrue(lockInputs.length === 1, "LockView exposes exactly one text input, found " + lockInputs.length)
        for (var i = 0; i < lockInputs.length; i++) {
          var hints = lockInputs[i].inputMethodHints
          root.assertTrue((hints & root.imhHiddenText) !== 0, "lock input hides the IME preedit")
          root.assertTrue((hints & root.imhSensitiveData) !== 0, "lock input marks data sensitive")
          root.assertTrue((hints & root.imhNoPredictiveText) !== 0, "lock input disables predictive text")
        }

        // Kit TextField: masked, and only masked, fields hide the preedit.
        var fieldComponent = Qt.createComponent("file://" + root.rootPath + "/shell/Ui/TextField.qml", Component.PreferSynchronous)
        if (fieldComponent.status !== Component.Ready) {
          root.fail("TextField failed to load: " + fieldComponent.errorString())
          root.writeResult()
          return
        }
        var secret = fieldComponent.createObject(host, { password: true })
        if (!secret) {
          root.fail("TextField(password) failed to instantiate")
        } else {
          var secretHints = secret.inputMethodHints
          root.assertTrue((secretHints & root.imhHiddenText) !== 0, "password TextField hides the IME preedit")
          root.assertTrue((secretHints & root.imhSensitiveData) !== 0, "password TextField marks data sensitive")
        }
        var plain = fieldComponent.createObject(host, { password: false })
        if (!plain) {
          root.fail("TextField(plain) failed to instantiate")
        } else {
          root.assertTrue((plain.inputMethodHints & root.imhHiddenText) === 0, "plain TextField keeps the IME enabled")
        }
      } catch (err) {
        root.fail("unexpected error: " + err)
      }
      root.writeResult()
    }
  }

  Component.onCompleted: Qt.callLater(function() {})
}
