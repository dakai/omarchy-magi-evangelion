import QtQuick
import Quickshell
import Quickshell.Wayland

// Écran MAGI sur le bureau (couche Bottom : au-dessus du fond d'écran, sous les fenêtres).
// MELCHIOR•1 = CPU, BALTHASAR•2 = RAM, CASPER•3 = batterie. Chaque ordinateur vote
// 承認 (approuvé) ou 否決 (rejeté) ; la résolution suit la majorité, comme dans l'anime.
// Fenêtre transparente aux clics (mask vide) ; les mesures viennent de MagiStats.
Item {
  id: root

  MagiStats { id: stats }

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
        cpu: stats.cpu; ram: stats.ram
        battery: stats.battery; batteryStatus: stats.batteryStatus
        cpuOk: stats.cpuOk; ramOk: stats.ramOk; batteryOk: stats.batteryOk
        votes: stats.votes
      }
    }
  }
}
