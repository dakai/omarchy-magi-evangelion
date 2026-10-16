import QtQuick
import Quickshell.Io

// Lecture des mesures pour les trois ordinateurs MAGI, partagée par l'écran
// du bureau et le widget de barre. Une lecture de /proc et /sys toutes les 2 s.
// MELCHIOR•1 = CPU, BALTHASAR•2 = RAM, CASPER•3 = batterie ; vote à la majorité.
Item {
  id: root

  property bool running: true
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
  readonly property bool passed: votes >= 2

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
    interval: 2000; repeat: true; running: root.running; triggeredOnStart: true
    onTriggered: if (!statsProc.running) statsProc.running = true
  }
}
