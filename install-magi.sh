#!/usr/bin/env bash
# MAGI — Evangelion desktop widget for Omarchy
# MELCHIOR (CPU), BALTHASAR (RAM) and CASPER (battery) vote 承認/否決 by majority.
# Install:   bash install-magi.sh
# Remove:    omarchy plugin remove evangelion.magi
set -euo pipefail

command -v omarchy >/dev/null || { echo "This needs Omarchy (https://omarchy.org)." >&2; exit 1; }

DIR="$HOME/.config/omarchy/plugins/evangelion.magi"
mkdir -p "$DIR"
echo "Installing MAGI into $DIR"

cat > "$DIR/manifest.json" <<'MAGI_EOF'
{
  "schemaVersion": 1,
  "id": "evangelion.magi",
  "name": "MAGI",
  "version": "1.0.0",
  "author": "remulef",
  "license": "MIT",
  "description": "Evangelion MAGI deliberation screen on your desktop: MELCHIOR (CPU), BALTHASAR (RAM) and CASPER (battery) vote 承認/否決 by majority.",
  "kinds": [
    "service"
  ],
  "entryPoints": {
    "service": "Service.qml"
  }
}
MAGI_EOF

cat > "$DIR/Service.qml" <<'MAGI_EOF'
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Écran MAGI sur le bureau (couche Bottom : au-dessus du fond d'écran, sous les fenêtres).
// MELCHIOR•1 = CPU, BALTHASAR•2 = RAM, CASPER•3 = batterie. Chaque ordinateur vote
// 承認 (approuvé) ou 否決 (rejeté) ; la résolution suit la majorité, comme dans l'anime.
// Fenêtre transparente aux clics (mask vide), une lecture de /proc toutes les 2 s.
Item {
  id: root

  property real cpu: 0
  property real ram: 0
  property int battery: -1
  property string batteryStatus: ""
  property var _lastCpu: null

  readonly property bool cpuOk: cpu < 85
  readonly property bool ramOk: ram < 90
  readonly property bool batteryOk: battery < 0 || battery >= 20
                                    || batteryStatus === "Charging" || batteryStatus === "Full"
  readonly property int votes: (cpuOk ? 1 : 0) + (ramOk ? 1 : 0) + (batteryOk ? 1 : 0)

  function parse(text) {
    const lines = text.trim().split("\n")
    const f = lines[0].trim().split(/\s+/).slice(1).map(Number)
    const idle = f[3] + (f[4] || 0)
    const total = f.reduce((a, b) => a + b, 0)
    if (_lastCpu && total > _lastCpu.total)
      cpu = 100 * (1 - (idle - _lastCpu.idle) / (total - _lastCpu.total))
    _lastCpu = { idle: idle, total: total }

    let memTotal = 0, memAvail = 0
    for (const l of lines) {
      if (l.startsWith("MemTotal:")) memTotal = parseInt(l.split(/\s+/)[1])
      else if (l.startsWith("MemAvailable:")) memAvail = parseInt(l.split(/\s+/)[1])
    }
    if (memTotal > 0) ram = 100 * (1 - memAvail / memTotal)

    const cap = lines.find(l => /^\d+$/.test(l.trim()))
    battery = cap !== undefined ? parseInt(cap) : -1
    batteryStatus = lines.length ? lines[lines.length - 1].trim() : ""
  }

  Process {
    id: statsProc
    command: ["sh", "-c",
      "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo; " +
      "for b in /sys/class/power_supply/BAT*; do cat \"$b/capacity\" \"$b/status\"; break; done 2>/dev/null"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parse(this.text)
    }
  }

  Timer {
    interval: 2000; repeat: true; running: true; triggeredOnStart: true
    onTriggered: if (!statsProc.running) statsProc.running = true
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      anchors { top: true; left: true }
      margins { top: 60; left: 40 }
      implicitWidth: 600
      implicitHeight: 440
      color: "transparent"

      WlrLayershell.namespace: "evangelion-magi"
      WlrLayershell.layer: WlrLayer.Bottom
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      mask: Region {}

      MagiView {
        anchors.fill: parent
        cpu: root.cpu; ram: root.ram
        battery: root.battery; batteryStatus: root.batteryStatus
        cpuOk: root.cpuOk; ramOk: root.ramOk; batteryOk: root.batteryOk
        votes: root.votes
      }
    }
  }
}
MAGI_EOF

cat > "$DIR/MagiPanel.qml" <<'MAGI_EOF'
import QtQuick
import QtQuick.Shapes

// Un des trois ordinateurs MAGI : contour biseauté + nom, mesure et vote.
// Les coordonnées sont celles du parent (MagiView), pour coller au schéma de l'anime.
Item {
  id: panel
  anchors.fill: parent

  property var points: []          // [Qt.point, ...] contour du panneau
  property rect content            // zone où placer le texte
  property string name: ""
  property string metric: ""
  property string valueText: "--"
  property bool approved: true
  property bool flipped: false     // nom à droite (MELCHIOR)

  readonly property color okColor: "#86E33F"
  readonly property color denyColor: "#E46166"
  readonly property color stateColor: approved ? okColor : denyColor

  property real pulse: 1.0
  SequentialAnimation on pulse {
    running: !panel.approved
    loops: Animation.Infinite
    NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
    NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
    onRunningChanged: if (!running) panel.pulse = 1.0
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: 2
      strokeColor: panel.stateColor
      fillColor: Qt.rgba(panel.stateColor.r, panel.stateColor.g, panel.stateColor.b,
                         (panel.approved ? 0.20 : 0.38) * panel.pulse)
      joinStyle: ShapePath.MiterJoin
      PathPolyline { path: panel.points.length ? panel.points.concat([panel.points[0]]) : [] }
    }
  }

  Item {
    x: panel.content.x; y: panel.content.y
    width: panel.content.width; height: panel.content.height

    Text {
      id: nameText
      text: panel.name
      color: "#F08A5D"
      font.family: "monospace"; font.pixelSize: 15; font.bold: true; font.letterSpacing: 2
      anchors.top: parent.top
      anchors.left: panel.flipped ? undefined : parent.left
      anchors.right: panel.flipped ? parent.right : undefined
    }
    Text {
      text: panel.metric + "  " + panel.valueText
      color: "#E6DDF5"
      font.family: "monospace"; font.pixelSize: 13; font.letterSpacing: 1
      anchors.top: nameText.bottom; anchors.topMargin: 2
      anchors.left: nameText.left; anchors.right: panel.flipped ? nameText.right : undefined
    }
    Text {
      text: panel.approved ? "承認" : "否決"
      color: panel.stateColor
      opacity: 0.55 + 0.45 * panel.pulse
      font.family: "Noto Sans CJK JP"; font.pixelSize: 44; font.weight: Font.Black
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
    }
  }
}
MAGI_EOF

cat > "$DIR/MagiView.qml" <<'MAGI_EOF'
import QtQuick
import QtQuick.Shapes

// Mise en page de l'écran MAGI (600×440), inspirée de la délibération des MAGI dans l'anime.
Item {
  id: view

  property real cpu: 0
  property real ram: 0
  property int battery: -1
  property string batteryStatus: ""
  property bool cpuOk: true
  property bool ramOk: true
  property bool batteryOk: true
  property int votes: 3

  readonly property color orange: "#F08A5D"
  readonly property color fg: "#E6DDF5"
  readonly property color okColor: "#86E33F"
  readonly property color denyColor: "#E46166"
  readonly property bool passed: votes >= 2

  // fond lisible par-dessus le ciel du fond d'écran
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(23 / 255, 17 / 255, 42 / 255, 0.78)
    border.color: Qt.rgba(240 / 255, 138 / 255, 93 / 255, 0.6)
    border.width: 1
  }

  // en-tête
  Text {
    x: 18; y: 10
    text: "MAGI SYSTEM"
    color: view.orange
    font.family: "monospace"; font.pixelSize: 22; font.bold: true; font.letterSpacing: 4
  }
  Repeater {
    model: [{ t: "提訴", y: 46 }, { t: "決議", y: 86 }]
    Rectangle {
      required property var modelData
      x: 18; y: modelData.y; width: 74; height: 32
      color: "transparent"; border.color: view.orange; border.width: 2
      Text {
        anchors.centerIn: parent
        text: parent.modelData.t
        color: view.orange
        font.family: "Noto Sans CJK JP"; font.pixelSize: 18; font.bold: true
      }
    }
  }
  Column {
    x: 428; y: 12; spacing: 1
    Repeater {
      model: ["CODE : 473", "FILE : MAGI_SYS", "EXTENTION : 3023", "EX_MODE : OFF", "PRIORITY : AAA"]
      Text {
        required property string modelData
        text: modelData
        color: view.orange
        font.family: "monospace"; font.pixelSize: 12; font.letterSpacing: 1
      }
    }
  }

  // liaisons entre les trois ordinateurs
  Shape {
    anchors.fill: parent
    ShapePath {
      strokeWidth: 6; strokeColor: Qt.rgba(240 / 255, 138 / 255, 93 / 255, 0.85); fillColor: "transparent"
      capStyle: ShapePath.FlatCap
      PathMove { x: 300; y: 190 } PathLine { x: 300; y: 236 }
      PathMove { x: 262; y: 300 } PathLine { x: 338; y: 300 }
    }
  }
  Text {
    x: 300 - width / 2; y: 254
    text: "MAGI"
    color: view.fg
    font.family: "monospace"; font.pixelSize: 18; font.bold: true; font.letterSpacing: 3
  }

  MagiPanel {
    name: "CASPER • 3"
    metric: "BATT"
    valueText: view.battery < 0 ? "N/A"
              : view.battery + "%" + (view.batteryStatus === "Charging" ? " ⚡" : "")
    approved: view.batteryOk
    points: [Qt.point(196, 50), Qt.point(404, 50), Qt.point(404, 150), Qt.point(364, 190),
             Qt.point(236, 190), Qt.point(196, 150)]
    content: Qt.rect(210, 58, 180, 124)
  }
  MagiPanel {
    name: "BALTHASAR • 2"
    metric: "RAM"
    valueText: Math.round(view.ram) + "%"
    approved: view.ramOk
    points: [Qt.point(24, 212), Qt.point(222, 212), Qt.point(262, 252), Qt.point(262, 364),
             Qt.point(24, 364)]
    content: Qt.rect(36, 220, 210, 136)
  }
  MagiPanel {
    name: "MELCHIOR • 1"
    metric: "CPU"
    valueText: Math.round(view.cpu) + "%"
    approved: view.cpuOk
    flipped: true
    points: [Qt.point(378, 212), Qt.point(576, 212), Qt.point(576, 364), Qt.point(338, 364),
             Qt.point(338, 252)]
    content: Qt.rect(354, 220, 210, 136)
  }

  // résolution à la majorité
  Rectangle {
    x: 24; y: 384; width: 552; height: 42
    color: Qt.rgba(view.passed ? 134 / 255 : 228 / 255, view.passed ? 227 / 255 : 97 / 255,
                   view.passed ? 63 / 255 : 102 / 255, 0.16)
    border.color: view.passed ? view.okColor : view.denyColor
    border.width: 2
    Row {
      anchors.centerIn: parent
      spacing: 18
      Text {
        text: "決議 : " + (view.passed ? "可決" : "否決")
        color: view.passed ? view.okColor : view.denyColor
        font.family: "Noto Sans CJK JP"; font.pixelSize: 20; font.weight: Font.Black
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        text: (view.passed ? "RESOLUTION APPROVED" : "RESOLUTION DENIED") + "   " + view.votes + " / 3"
        color: view.fg
        font.family: "monospace"; font.pixelSize: 13; font.letterSpacing: 2
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}
MAGI_EOF

omarchy plugin validate "$DIR"
# the running shell only knows plugins it has scanned; make it see the new folder first
omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
enabled=0
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if omarchy plugin enable evangelion.magi 2>/dev/null; then enabled=1; break; fi
  sleep 1
done
(( enabled )) || { echo "Installed, but could not enable it: run 'omarchy plugin enable evangelion.magi'." >&2; exit 1; }
echo "MAGI online. 承認 — open an empty workspace to see it."
