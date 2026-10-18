import QtQuick
import qs.Commons
import qs.Ui

// Widget de barre MAGI : un voyant par ordinateur (MELCHIOR, BALTHASAR, CASPER)
// et la résolution 可決 / 否決. Clic gauche = écran MAGI complet (popup),
// clic droit = vue réduite.
Panel {
  id: root
  moduleName: "evangelion.magi"
  ipcTarget: "evangelion.magi"

  readonly property color orange: "#F08A5D"
  readonly property color okColor: "#86E33F"
  readonly property color denyColor: "#E46166"
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // Vue de la barre : 0 = complète (MAGI ▮▮▮ 可決), 1 = sans la résolution,
  // 2 = voyants seuls. Le clic droit fait le tour et le choix est retenu dans
  // shell.json, comme pour les autres widgets (cf. omarchy.clock).
  readonly property int visualMode: {
    var v = Number(root.setting("visual", 0))
    return isFinite(v) ? (Math.floor(v) % 3 + 3) % 3 : 0
  }

  function cycleVisual() {
    var entry = { id: root.moduleName }
    for (var key in root.settings) if (key !== "id") entry[key] = root.settings[key]
    entry.visual = (visualMode + 1) % 3

    // Appliqué localement d'abord, pour que la vue change au clic même si
    // l'écriture shell.json est refusée ; elle revient par la barre sinon.
    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  property real pulse: 1.0
  SequentialAnimation on pulse {
    running: !stats.cpuOk || !stats.ramOk || !stats.batteryOk
    loops: Animation.Infinite
    NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
    NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
    onRunningChanged: if (!running) root.pulse = 1.0
  }

  MagiStats { id: stats }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    fixedWidth: root.bar && root.bar.vertical ? -1 : content.implicitWidth + Style.spaceReal(8.5) * 2
    fixedHeight: root.bar && root.bar.vertical ? content.implicitHeight + Style.spaceReal(6) * 2 : -1
    tooltipText: "MELCHIOR•1 CPU " + Math.round(stats.cpu) + "% " + (stats.cpuOk ? "承認" : "否決")
                 + "\nBALTHASAR•2 RAM " + Math.round(stats.ram) + "% " + (stats.ramOk ? "承認" : "否決")
                 + "\nCASPER•3 BATT " + (stats.battery < 0 ? "N/A" : stats.battery + "%") + " " + (stats.batteryOk ? "承認" : "否決")
                 + "\n決議 : " + (stats.passed ? "可決" : "否決") + "  " + stats.votes + " / 3"
                 + "\nclic droit : vue " + (root.visualMode + 1) + " / 3"
    onPressed: function(b) {
      if (b === Qt.RightButton) root.cycleVisual()
      else root.toggle()
    }

    Grid {
      id: content
      anchors.centerIn: parent
      flow: root.bar && root.bar.vertical ? Grid.TopToBottom : Grid.LeftToRight
      columns: root.bar && root.bar.vertical ? 1 : 3
      rows: root.bar && root.bar.vertical ? 3 : 1
      columnSpacing: Style.space(6)
      rowSpacing: Style.space(4)
      verticalItemAlignment: Grid.AlignVCenter
      horizontalItemAlignment: Grid.AlignHCenter

      Text {
        visible: root.visualMode < 2 && !(root.bar && root.bar.vertical)
        text: "MAGI"
        color: root.orange
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
        font.letterSpacing: 1.5
      }

      Grid {
        columns: root.bar && root.bar.vertical ? 1 : 3
        spacing: Style.space(2)
        Repeater {
          model: [stats.cpuOk, stats.ramOk, stats.batteryOk]
          Rectangle {
            width: Style.space(6); height: Style.space(12)
            color: modelData ? root.okColor : root.denyColor
            opacity: modelData ? 1 : 0.4 + 0.6 * root.pulse
          }
        }
      }

      Text {
        visible: root.visualMode === 0
        text: stats.passed ? "可決" : "否決"
        color: stats.passed ? root.okColor : root.denyColor
        font.family: "Noto Sans CJK JP"
        font.weight: Font.Black
        font.pixelSize: Style.font.body
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: 600
    contentHeight: 440

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      // MagiView est dessiné en coordonnées fixes 600×440 : on le met à l'échelle
      // de la zone réellement disponible dans le popup.
      MagiView {
        width: 600; height: 440
        transformOrigin: Item.TopLeft
        scale: Math.min(keyCatcher.width / 600, keyCatcher.height / 440)
        x: (keyCatcher.width - 600 * scale) / 2
        cpu: stats.cpu; ram: stats.ram
        battery: stats.battery; batteryStatus: stats.batteryStatus
        cpuOk: stats.cpuOk; ramOk: stats.ramOk; batteryOk: stats.batteryOk
        votes: stats.votes
      }
    }
  }
}
