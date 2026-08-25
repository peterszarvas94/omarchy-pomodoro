import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "io.github.peterszarvas94.pomodoro"

  property string phase: "idle"
  property bool running: false
  property double deadline: 0
  property int completed: 0
  property int promptIndex: 0
  property int remainingSeconds: 0
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  readonly property int focusMinutes: settingInt("focusMinutes", 25, 5, 120)
  readonly property int shortBreakMinutes: settingInt("shortBreakMinutes", 5, 1, 30)
  readonly property int longBreakMinutes: settingInt("longBreakMinutes", 15, 5, 60)
  readonly property int longBreakAfter: settingInt("longBreakAfter", 4, 2, 8)
  readonly property bool autoStartBreaks: settingBool("autoStartBreaks", false)
  readonly property bool autoStartFocus: settingBool("autoStartFocus", false)
  readonly property bool active: phase !== "idle"
  readonly property string displayText: active ? Model.formatSeconds(remainingSeconds) : ""
  readonly property string phaseLabel: phase === "focus" ? "Focus" : (phase === "shortBreak" ? "Short break" : (phase === "longBreak" ? "Long break" : "Ready"))
  readonly property string phaseIcon: phase === "focus" ? "󰄉" : (active ? "󰒆" : "󰅐")

  function settingInt(name, fallback, min, max) {
    var value = parseInt(String(setting(name, fallback)), 10)
    return isFinite(value) ? Math.max(min, Math.min(max, value)) : fallback
  }

  function settingBool(name, fallback) {
    var value = setting(name, fallback)
    return value === true || value === "true"
  }

  function persistSettings(values) {
    var entry = {id: root.moduleName}
    for (var key in root.settings) if (key !== "id") entry[key] = root.settings[key]
    for (var name in values) entry[name] = values[name]
    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function begin(nextPhase) {
    phase = nextPhase || "focus"
    remainingSeconds = Model.phaseMinutes(phase, focusMinutes, shortBreakMinutes, longBreakMinutes) * 60
    deadline = Date.now() + remainingSeconds * 1000
    running = true
    tick()
  }

  function start() {
    if (phase === "idle") begin("focus")
    else if (!running) {
      deadline = Date.now() + remainingSeconds * 1000
      running = true
    }
  }

  function pause() {
    if (!running) return
    tick()
    running = false
  }

  function reset() {
    running = false
    phase = "idle"
    deadline = 0
    remainingSeconds = 0
    completed = 0
  }

  function skip() {
    if (!active) return
    transition()
  }

  function snooze() {
    if (!active || phase === "focus") return
    running = false
    phase = "idle"
    deadline = 0
    remainingSeconds = 0
    notify("Break postponed", "Start it again when you can step away from the screen.")
  }

  function tick() {
    if (!active || !running) return
    remainingSeconds = Math.max(0, Math.ceil((deadline - Date.now()) / 1000))
    if (remainingSeconds <= 0) transition()
  }

  function transition() {
    var finished = phase
    if (finished === "focus") completed += 1
    var next = Model.nextPhase(finished, completed, longBreakAfter)
    var message = Model.prompt(finished === "focus" ? next : next, promptIndex++)
    running = false
    phase = next
    remainingSeconds = Model.phaseMinutes(next, focusMinutes, shortBreakMinutes, longBreakMinutes) * 60
    deadline = 0
    notify(message.title, message.body)
    if ((next === "focus" && autoStartFocus) || (next !== "focus" && autoStartBreaks)) start()
  }

  function notify(title, body) {
    notificationProcess.command = ["notify-send", "--app-name=Healthy Pomodoro", title, body]
    notificationProcess.running = true
  }

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.hostWidget = root
    target.bar = root.bar
    target.anchorItem = button
    target.settings = root.settings
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Timer {
    interval: 500
    running: root.running
    repeat: true
    triggeredOnStart: true
    onTriggered: root.tick()
  }

  Process { id: notificationProcess }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  IpcHandler {
    target: "io.github.peterszarvas94.pomodoro"
    function open() { root.open() }
    function close() { root.close() }
    function toggle() { root.togglePanel() }
    function start(): string { root.start(); return "ok" }
    function pause(): string { root.pause(); return "ok" }
    function reset(): string { root.reset(); return "ok" }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.phaseIcon
    active: root.active && root.phase !== "focus"
    tooltipText: root.active ? root.phaseLabel + " · " + root.displayText : "Start a healthy focus session"
    onPressed: function(code) {
      if (code === Qt.RightButton) root.running ? root.pause() : root.start()
      else if (code === Qt.MiddleButton) root.skip()
      else root.togglePanel()
    }
  }
}
