import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "lattice" as Lattice

PlasmoidItem {
    id: root

    // ---- config-derived ---------------------------------------------------
    readonly property color accent: plasmoid.configuration.accentColor.length > 0
        ? plasmoid.configuration.accentColor : Lattice.Theme.accentDefault
    readonly property real scrim: plasmoid.configuration.scrimStrength

    // ---- live model -------------------------------------------------------
    property real cpuPct: 0
    property real memUsed: 0     // GB
    property real memTotal: 0
    property real gpuPct: 0
    property real vramUsed: 0    // GB
    property real vramTotal: 0
    property real gpuTemp: 0
    property string gpuName: ""
    property bool hasGpu: vramTotal > 0
    property var cpuHist: []
    property var gpuHist: []
    property var _prevCpu: null

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    function pushHist(arr, v, n) {
        var a = arr.slice(); a.push(v);
        if (a.length > n) a = a.slice(a.length - n);
        return a;
    }
    function fmt(x, d) { return Number(x).toFixed(d === undefined ? 1 : d); }

    // ---- acquisition ------------------------------------------------------
    P5Support.DataSource {
        id: monitor
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source);
            root.parse(data["stdout"] || "");
        }
        function poll() {
            var i = plasmoid.configuration.gpuIndex;
            var cmd =
                "grep '^cpu ' /proc/stat" +
                "; echo ---" +
                "; grep -E 'MemTotal|MemAvailable' /proc/meminfo" +
                "; echo ---" +
                "; nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu" +
                " --format=csv,noheader,nounits -i " + i + " 2>/dev/null";
            connectSource(cmd);
        }
    }

    P5Support.DataSource {
        id: nameSrc
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source);
            var s = (data["stdout"] || "").trim();
            if (s.length > 0) root.gpuName = s.replace(/NVIDIA\s+GeForce\s+/i, "");
        }
        function fetch() {
            connectSource("nvidia-smi --query-gpu=name --format=csv,noheader -i "
                + plasmoid.configuration.gpuIndex + " 2>/dev/null");
        }
    }

    Timer {
        interval: plasmoid.configuration.pollInterval
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: monitor.poll()
    }
    Component.onCompleted: nameSrc.fetch()

    // Activity LED: lit briefly whenever a sample lands. Stepped on purpose — an
    // infinite opacity tween makes Qt Quick redraw the whole desktop view every
    // vsync (240 fps on a 240 Hz panel) for a dot.
    property bool beat: false
    Timer { id: beatOff; interval: 160; onTriggered: root.beat = false }

    function parse(out) {
        root.beat = true; beatOff.restart();
        var s = out.split("---");
        // CPU — delta of jiffies between polls
        if (s[0]) {
            var p = s[0].trim().split(/\s+/);   // cpu user nice system idle iowait ...
            if (p.length >= 5) {
                var n = p.slice(1).map(Number);
                var idle = n[3] + (n[4] || 0);
                var total = n.reduce(function (a, b) { return a + b; }, 0);
                if (_prevCpu) {
                    var dt = total - _prevCpu.total;
                    var di = idle - _prevCpu.idle;
                    if (dt > 0) cpuPct = Math.max(0, Math.min(100, (1 - di / dt) * 100));
                }
                _prevCpu = { total: total, idle: idle };
            }
        }
        // Memory
        if (s[1]) {
            var mt = s[1].match(/MemTotal:\s+(\d+)/);
            var ma = s[1].match(/MemAvailable:\s+(\d+)/);
            if (mt && ma) {
                memTotal = mt[1] / 1048576;
                memUsed = (mt[1] - ma[1]) / 1048576;
            }
        }
        // GPU
        if (s[2]) {
            var g = s[2].trim().split(",");
            if (g.length >= 4 && g[2].trim().length > 0) {
                gpuPct = Number(g[0]);
                vramUsed = Number(g[1]) / 1024;
                vramTotal = Number(g[2]) / 1024;
                gpuTemp = Number(g[3]);
            }
        }
        cpuHist = pushHist(cpuHist, cpuPct, 64);
        if (hasGpu) gpuHist = pushHist(gpuHist, gpuPct, 64);
    }

    // ---- panel (compact) --------------------------------------------------
    compactRepresentation: RowLayout {
        spacing: Lattice.Theme.sm
        Lattice.MonoText {
            text: " " + Math.round(root.gpuPct) + "%"   // nf chip glyph
            tone: root.accent
            font.pixelSize: Lattice.Theme.fsCaption
        }
        Lattice.MonoText {
            text: root.fmt(root.vramUsed, 1) + "G"
            tone: Lattice.Theme.dim
            font.pixelSize: Lattice.Theme.fsCaption
            visible: root.hasGpu
        }
        MouseArea { anchors.fill: parent; onClicked: root.expanded = !root.expanded }
    }

    // ---- desktop (full) ---------------------------------------------------
    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 13
        Layout.minimumHeight: content.implicitHeight + Lattice.Theme.md * 2
        implicitWidth: Kirigami.Units.gridUnit * 15
        implicitHeight: content.implicitHeight + Lattice.Theme.md * 2

        Lattice.Scrim { anchors.fill: parent; strength: root.scrim }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Lattice.Theme.md
            spacing: Lattice.Theme.sm

            // header
            RowLayout {
                Layout.fillWidth: true
                spacing: Lattice.Theme.sm
                Lattice.Caption { text: "lattice"; tone: Lattice.Theme.faint }
                Item { Layout.fillWidth: true }
                Rectangle {   // live pulse — blinks on each sample
                    width: Lattice.Theme.xs; height: width; radius: width / 2
                    color: root.accent
                    opacity: root.beat ? 1.0 : 0.3
                }
            }

            // ===== GPU (hero) =====
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Lattice.Theme.xs
                visible: plasmoid.configuration.showGpu

                RowLayout {
                    Layout.fillWidth: true
                    Lattice.Caption { text: "GPU" }
                    Item { Layout.fillWidth: true }
                    Lattice.MonoText {
                        text: root.hasGpu ? root.gpuName : "not detected"
                        tone: Lattice.Theme.faint
                        font.pixelSize: Lattice.Theme.fsMicro
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 9
                    }
                }
                Lattice.Hairline { Layout.fillWidth: true; Layout.bottomMargin: Lattice.Theme.xs }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Lattice.Theme.md
                    // hero number
                    Row {
                        spacing: 1
                        Lattice.MonoText {
                            text: root.hasGpu ? Math.round(root.gpuPct) : "—"
                            tone: Lattice.Theme.ink
                            font.pixelSize: Lattice.Theme.fsHero
                            font.weight: Font.DemiBold
                        }
                        Lattice.MonoText {
                            text: "%"; tone: Lattice.Theme.dim
                            font.pixelSize: Lattice.Theme.fsReadout
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: Lattice.Theme.xs
                        }
                    }
                    Item { Layout.fillWidth: true }
                    // temp
                    ColumnLayout {
                        spacing: 0
                        Layout.alignment: Qt.AlignBottom
                        Lattice.MonoText {
                            text: root.hasGpu ? Math.round(root.gpuTemp) + "°" : "—"
                            tone: root.gpuTemp > 80 ? Lattice.Theme.hot
                                 : root.gpuTemp > 70 ? Lattice.Theme.warn : Lattice.Theme.dim
                            font.pixelSize: Lattice.Theme.fsReadout
                            Layout.alignment: Qt.AlignRight
                        }
                        Lattice.Caption {
                            text: "temp"; tone: Lattice.Theme.faint
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }

                Lattice.Sparkline {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.6
                    values: root.gpuHist
                    maxValue: 100
                    line: root.accent
                    visible: root.hasGpu
                }

                Lattice.Meter {
                    Layout.fillWidth: true
                    Layout.topMargin: Lattice.Theme.xs
                    label: "VRAM"
                    value: root.vramUsed
                    max: root.vramTotal > 0 ? root.vramTotal : 1
                    valueText: root.fmt(root.vramUsed, 1) + " / " + root.fmt(root.vramTotal, 1) + " GB"
                    accent: root.accent
                    colorByLevel: true
                    visible: root.hasGpu
                }
            }

            // ===== CPU =====
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Lattice.Theme.sm
                spacing: Lattice.Theme.xs
                visible: plasmoid.configuration.showCpu

                RowLayout {
                    Layout.fillWidth: true
                    Lattice.Caption { text: "CPU" }
                    Item { Layout.fillWidth: true }
                    Lattice.MonoText {
                        text: Math.round(root.cpuPct) + "%"
                        tone: Lattice.Theme.ink
                        font.pixelSize: Lattice.Theme.fsCaption
                    }
                }
                Lattice.Sparkline {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
                    values: root.cpuHist
                    maxValue: 100
                    line: Lattice.Theme.fg(0.7)
                }
            }

            // ===== Memory =====
            Lattice.Meter {
                Layout.fillWidth: true
                Layout.topMargin: Lattice.Theme.sm
                visible: plasmoid.configuration.showRam
                label: "MEM"
                value: root.memUsed
                max: root.memTotal > 0 ? root.memTotal : 1
                valueText: root.fmt(root.memUsed, 1) + " / " + root.fmt(root.memTotal, 0) + " GB"
                accent: root.accent
                colorByLevel: true
            }
        }
    }
}
