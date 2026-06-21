import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "lattice" as Lattice

PlasmoidItem {
    id: root

    readonly property color accent: plasmoid.configuration.accentColor.length > 0
        ? plasmoid.configuration.accentColor : Lattice.Theme.accentDefault
    readonly property real scrim: plasmoid.configuration.scrimStrength

    property real downRate: 0   // bytes/s
    property real upRate: 0
    property real peakDown: 1
    property real peakUp: 1
    property string iface: ""
    property var downHist: []
    property var upHist: []
    property var _prev: null    // { rx, tx, t }

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    function pushHist(a, v, n) { var b = a.slice(); b.push(v); if (b.length > n) b = b.slice(b.length - n); return b; }

    function fmtRate(bps) {
        var u = ["B/s", "K/s", "M/s", "G/s"], i = 0, v = bps;
        while (v >= 1024 && i < u.length - 1) { v /= 1024; i++; }
        var s = v >= 100 || i === 0 ? v.toFixed(0) : v.toFixed(1);
        return [s, u[i]];
    }

    P5Support.DataSource {
        id: net
        engine: "executable"
        connectedSources: []
        onNewData: (s, d) => { disconnectSource(s); root.parse(d["stdout"] || ""); }
        function poll() { connectSource("cat /proc/net/dev"); }
    }
    Timer {
        interval: plasmoid.configuration.pollInterval
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: net.poll()
    }

    function parse(out) {
        var lines = out.split("\n");
        var rx = 0, tx = 0, best = "", bestRx = -1;
        for (var i = 2; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line.length === 0) continue;
            var c = line.split(":");
            if (c.length < 2) continue;
            var name = c[0].trim();
            if (name === "lo" || name.indexOf("docker") === 0 || name.indexOf("veth") === 0
                || name.indexOf("br-") === 0 || name.indexOf("virbr") === 0) continue;
            var f = c[1].trim().split(/\s+/).map(Number);
            if (f.length < 9) continue;
            rx += f[0]; tx += f[8];
            if (f[0] > bestRx) { bestRx = f[0]; best = name; }
        }
        if (best.length > 0) iface = best;

        var nowT = Date.now();
        if (_prev) {
            var dt = (nowT - _prev.t) / 1000;
            if (dt > 0) {
                downRate = Math.max(0, (rx - _prev.rx) / dt);
                upRate = Math.max(0, (tx - _prev.tx) / dt);
                peakDown = Math.max(peakDown, downRate);
                peakUp = Math.max(peakUp, upRate);
                downHist = pushHist(downHist, downRate, 64);
                upHist = pushHist(upHist, upRate, 64);
            }
        }
        _prev = { rx: rx, tx: tx, t: nowT };
    }

    // ---- compact ----------------------------------------------------------
    compactRepresentation: RowLayout {
        spacing: Lattice.Theme.xs
        Lattice.MonoText {
            text: "↓" + root.fmtRate(root.downRate)[0]
            tone: root.accent; font.pixelSize: Lattice.Theme.fsCaption
        }
        Lattice.MonoText {
            text: "↑" + root.fmtRate(root.upRate)[0]
            tone: Lattice.Theme.dim; font.pixelSize: Lattice.Theme.fsCaption
        }
        MouseArea { anchors.fill: parent; onClicked: root.expanded = !root.expanded }
    }

    // ---- full -------------------------------------------------------------
    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 12
        implicitWidth: Kirigami.Units.gridUnit * 14
        implicitHeight: col.implicitHeight + Lattice.Theme.md * 2

        Lattice.Scrim { anchors.fill: parent; strength: root.scrim }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: Lattice.Theme.md
            spacing: Lattice.Theme.sm

            RowLayout {
                Layout.fillWidth: true
                Lattice.Caption { text: "net" }
                Item { Layout.fillWidth: true }
                Lattice.MonoText { text: root.iface; tone: Lattice.Theme.faint; font.pixelSize: Lattice.Theme.fsMicro }
            }
            Lattice.Hairline { Layout.fillWidth: true }

            // DOWN
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Lattice.Theme.xs
                spacing: Lattice.Theme.xs
                Lattice.MonoText { text: "↓"; tone: root.accent; font.pixelSize: Lattice.Theme.fsReadout }
                Lattice.MonoText {
                    text: root.fmtRate(root.downRate)[0]
                    tone: Lattice.Theme.ink; font.pixelSize: Lattice.Theme.fsReadout; font.weight: Font.DemiBold
                }
                Lattice.Caption { text: root.fmtRate(root.downRate)[1]; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 3 }
                Item { Layout.fillWidth: true }
            }
            Lattice.Sparkline {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.4
                values: root.downHist
                maxValue: 0
                line: root.accent
            }

            // UP
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Lattice.Theme.xs
                spacing: Lattice.Theme.xs
                Lattice.MonoText { text: "↑"; tone: Lattice.Theme.dim; font.pixelSize: Lattice.Theme.fsReadout }
                Lattice.MonoText {
                    text: root.fmtRate(root.upRate)[0]
                    tone: Lattice.Theme.ink; font.pixelSize: Lattice.Theme.fsReadout; font.weight: Font.DemiBold
                }
                Lattice.Caption { text: root.fmtRate(root.upRate)[1]; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 3 }
                Item { Layout.fillWidth: true }
            }
            Lattice.Sparkline {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.4
                values: root.upHist
                maxValue: 0
                line: Lattice.Theme.fg(0.6)
            }

            Lattice.Hairline { Layout.fillWidth: true; Layout.topMargin: Lattice.Theme.xs }
            RowLayout {
                Layout.fillWidth: true
                Lattice.Caption { text: "peak"; tone: Lattice.Theme.faint }
                Item { Layout.fillWidth: true }
                Lattice.MonoText {
                    text: "↓" + root.fmtRate(root.peakDown).join("") + "  ↑" + root.fmtRate(root.peakUp).join("")
                    tone: Lattice.Theme.dim; font.pixelSize: Lattice.Theme.fsMicro
                }
            }
        }
    }
}
