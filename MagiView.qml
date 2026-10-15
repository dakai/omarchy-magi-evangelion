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
