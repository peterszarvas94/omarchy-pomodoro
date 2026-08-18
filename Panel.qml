import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "peti.pomodoro"
  ipcTarget: "peti.pomodoro"
  manageIpc: false

  property var hostWidget: null
  property var anchorItem: null
  property bool cursorActive: false
  property int cursorIndex: 0
  readonly property var barIdentity: hostWidget || root
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color accent: Color.accent
  readonly property color dim: Qt.darker(foreground, 1.5)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string preset: {
    if (!hostWidget) return "classic"
    if (hostWidget.focusMinutes === 25 && hostWidget.shortBreakMinutes === 5 && hostWidget.longBreakMinutes === 15) return "classic"
    if (hostWidget.focusMinutes === 30 && hostWidget.shortBreakMinutes === 5 && hostWidget.longBreakMinutes === 15) return "move30"
    if (hostWidget.focusMinutes === 50 && hostWidget.shortBreakMinutes === 10 && hostWidget.longBreakMinutes === 20) return "deep"
    return "custom"
  }

  function open() {
    root.controller.show()
    Qt.callLater(function() {
      if (contentScroll) contentScroll.contentY = 0
      if (keyCatcher) keyCatcher.forceActiveFocus()
    })
  }
  function close() { root.controller.hide() }
  function toggle() { root.opened ? root.close() : root.open() }
  function switchPanel(direction) { return bar && bar.switchPanelFrom ? bar.switchPanelFrom(root.barIdentity, direction) : false }
  function save(values) { if (hostWidget) hostWidget.persistSettings(values) }
  function applyPreset(value) {
    if (value === "classic") save({focusMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15})
    else if (value === "move30") save({focusMinutes: 30, shortBreakMinutes: 5, longBreakMinutes: 15})
    else if (value === "deep") save({focusMinutes: 50, shortBreakMinutes: 10, longBreakMinutes: 20})
  }

  function setCursor(index) {
    cursorActive = true
    cursorIndex = Math.max(0, Math.min(11, index))
  }

  function moveCursor(dx, dy) {
    if (dx !== 0) {
      setCursor((cursorIndex + (dx > 0 ? 1 : -1) + 12) % 12)
      return
    }
    if (dy === 0 || cursorIndex < 6 || cursorIndex > 9 || !hostWidget) return
    var direction = dy < 0 ? 1 : -1
    if (cursorIndex === 6) save({focusMinutes: Math.max(5, Math.min(120, hostWidget.focusMinutes + direction * 5))})
    else if (cursorIndex === 7) save({shortBreakMinutes: Math.max(1, Math.min(30, hostWidget.shortBreakMinutes + direction))})
    else if (cursorIndex === 8) save({longBreakMinutes: Math.max(5, Math.min(60, hostWidget.longBreakMinutes + direction * 5))})
    else if (cursorIndex === 9) save({longBreakAfter: Math.max(2, Math.min(8, hostWidget.longBreakAfter + direction))})
  }

  function activateCursor() {
    if (!hostWidget) return
    if (cursorIndex === 0) hostWidget.running ? hostWidget.pause() : hostWidget.start()
    else if (cursorIndex === 1) hostWidget.reset()
    else if (cursorIndex === 2) hostWidget.skip()
    else if (cursorIndex === 3) applyPreset("classic")
    else if (cursorIndex === 4) applyPreset("move30")
    else if (cursorIndex === 5) applyPreset("deep")
    else if (cursorIndex === 10) save({autoStartBreaks: !hostWidget.autoStartBreaks})
    else if (cursorIndex === 11) save({autoStartFocus: !hostWidget.autoStartFocus})
  }

  onOpenedChanged: if (opened) {
    cursorActive = false
    cursorIndex = 0
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(460))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(640))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) { root.moveCursor(dx, dy) }
      onActivateRequested: root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (!hostWidget) return
        if (t === "s" || t === "S") hostWidget.start()
        else if (t === "p" || t === "P") hostWidget.pause()
        else if (t === "r" || t === "R") hostWidget.reset()
        else if (t === "n" || t === "N") hostWidget.skip()
        else if (t === "z" || t === "Z") hostWidget.snooze()
      }

      Flickable {
        id: contentScroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: content
          width: contentScroll.width
          spacing: Style.space(12)

          PanelHero {
            width: parent.width
            title: hostWidget ? hostWidget.phaseLabel : "Healthy Pomodoro"
            meta: hostWidget && hostWidget.active ? Model.formatSeconds(hostWidget.remainingSeconds) : "Ready when you are"
            detail: hostWidget && hostWidget.completed > 0 ? hostWidget.completed + " DONE" : ""
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconComponent: Component {
              Text {
                text: hostWidget ? hostWidget.phaseIcon : "󰅐"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }
          }

          RowLayout {
            width: parent.width
            spacing: Style.spacing.md

            Button {
              Layout.fillWidth: true
              text: hostWidget && hostWidget.running ? "Pause" : (hostWidget && hostWidget.active ? "Resume" : "Start")
              iconText: hostWidget && hostWidget.running ? "󰏤" : "󰐊"
              bordered: true
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              hasCursor: root.cursorActive && root.cursorIndex === 0
              onHovered: function(on) { if (on) root.setCursor(0) }
              onClicked: if (hostWidget) hostWidget.running ? hostWidget.pause() : hostWidget.start()
            }
            Button {
              Layout.fillWidth: true
              text: "Reset"
              iconText: "󰑐"
              bordered: true
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              hasCursor: root.cursorActive && root.cursorIndex === 1
              onHovered: function(on) { if (on) root.setCursor(1) }
              onClicked: if (hostWidget) hostWidget.reset()
            }
            Button {
              Layout.fillWidth: true
              text: "Skip"
              iconText: "󰒭"
              bordered: true
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              hasCursor: root.cursorActive && root.cursorIndex === 2
              onHovered: function(on) { if (on) root.setCursor(2) }
              opacity: hostWidget && hostWidget.active ? 1 : 0.45
              onClicked: if (hostWidget && hostWidget.active) hostWidget.skip()
            }
          }

          PanelSeparator { width: parent.width; foreground: root.foreground }

          Column {
            width: parent.width
            spacing: Style.space(10)

            PanelSectionHeader {
              width: parent.width
              text: "CADENCE"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            ButtonGroup {
              width: parent.width
              options: [
                {value: "classic", label: "25 / 5 / 15", tooltip: "Classic Pomodoro"},
                {value: "move30", label: "30 / 5 / 15", tooltip: "Movement break every 30 minutes"},
                {value: "deep", label: "50 / 10 / 20", tooltip: "Longer focus blocks"}
              ]
              value: root.preset
              cursorIndex: root.cursorActive && root.cursorIndex >= 3 && root.cursorIndex <= 5 ? root.cursorIndex - 3 : -1
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              onHovered: function(index, on) { if (on) root.setCursor(index + 3) }
              onChanged: function(value) { root.applyPreset(value) }
            }

            Grid {
              id: cadenceGrid
              width: parent.width
              columns: 2
              spacing: Style.spacing.lg

              NumberField {
                id: focusField
                width: (cadenceGrid.width - cadenceGrid.spacing) / 2
                fieldWidth: width
                label: "FOCUS"
                value: hostWidget ? hostWidget.focusMinutes : 25
                from: 5; to: 120; stepSize: 5
                foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
                hasCursor: root.cursorActive && root.cursorIndex === 6
                onHovered: function(on) { if (on) root.setCursor(6) }
                onModified: function(value) { root.save({focusMinutes: value}) }
              }
              NumberField {
                id: shortBreakField
                width: (cadenceGrid.width - cadenceGrid.spacing) / 2
                fieldWidth: width
                label: "SHORT BREAK"
                value: hostWidget ? hostWidget.shortBreakMinutes : 5
                from: 1; to: 30; stepSize: 1
                foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
                hasCursor: root.cursorActive && root.cursorIndex === 7
                onHovered: function(on) { if (on) root.setCursor(7) }
                onModified: function(value) { root.save({shortBreakMinutes: value}) }
              }
              NumberField {
                id: longBreakField
                width: (cadenceGrid.width - cadenceGrid.spacing) / 2
                fieldWidth: width
                label: "LONG BREAK"
                value: hostWidget ? hostWidget.longBreakMinutes : 15
                from: 5; to: 60; stepSize: 5
                foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
                hasCursor: root.cursorActive && root.cursorIndex === 8
                onHovered: function(on) { if (on) root.setCursor(8) }
                onModified: function(value) { root.save({longBreakMinutes: value}) }
              }
              NumberField {
                id: afterField
                width: (cadenceGrid.width - cadenceGrid.spacing) / 2
                fieldWidth: width
                label: "AFTER"
                value: hostWidget ? hostWidget.longBreakAfter : 4
                from: 2; to: 8; stepSize: 1
                foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
                hasCursor: root.cursorActive && root.cursorIndex === 9
                onHovered: function(on) { if (on) root.setCursor(9) }
                onModified: function(value) { root.save({longBreakAfter: value}) }
              }
            }
          }

          PanelSeparator { width: parent.width; foreground: root.foreground }

          Column {
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              width: parent.width
              text: "TRANSITIONS"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Toggle {
              width: parent.width
              label: "Auto-start breaks"
              description: "Begin the movement timer when focus ends"
              checked: hostWidget ? hostWidget.autoStartBreaks : false
              hasCursor: root.cursorActive && root.cursorIndex === 10
              foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
              onHovered: function(on) { if (on) root.setCursor(10) }
              onClicked: root.save({autoStartBreaks: !checked})
            }
            Toggle {
              width: parent.width
              label: "Auto-start focus"
              description: "Begin the next focus block when a break ends"
              checked: hostWidget ? hostWidget.autoStartFocus : false
              hasCursor: root.cursorActive && root.cursorIndex === 11
              foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
              onHovered: function(on) { if (on) root.setCursor(11) }
              onClicked: root.save({autoStartFocus: !checked})
            }
          }

          BorderSurface {
            width: parent.width
            implicitHeight: guidance.implicitHeight + Style.spacing.xl * 2
            color: Style.normalFillFor(root.foreground, root.accent)
            borderSpec: Border.controlSpec("normal", root.foreground, root.accent)
            radius: Style.cornerRadius

            Text {
              id: guidance
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: Style.space(12)
              anchors.rightMargin: Style.space(12)
              text: "Breaks are invitations, never forced. Stand, walk lightly, change posture, stretch gently, and look away from the screen."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }
          }
        }
      }
    }
  }
}
