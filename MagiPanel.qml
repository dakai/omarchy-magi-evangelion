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
