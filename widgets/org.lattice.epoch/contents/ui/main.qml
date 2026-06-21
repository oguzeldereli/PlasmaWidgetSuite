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

    property var now: new Date()
    property real uptimeSecs: 0

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    P5Support.DataSource {
        id: up
        engine: "executable"
        connectedSources: []
        onNewData: (s, d) => {
            disconnectSource(s);
            var t = parseFloat((d["stdout"] || "0").trim().split(" ")[0]);
            if (!isNaN(t)) root.uptimeSecs = t;
        }
        function poll() { connectSource("cat /proc/uptime"); }
    }
    Timer { interval: 15000; running: true; repeat: true; triggeredOnStart: true; onTriggered: up.poll() }

    // ---- temporal helpers -------------------------------------------------
    function p2(n) { return (n < 10 ? "0" : "") + n; }
    function isLeap(y) { return (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0; }
    function daysInYear(y) { return isLeap(y) ? 366 : 365; }
    function dayOfYear(d) {
        var start = new Date(d.getFullYear(), 0, 0);
        return Math.floor((d - start) / 86400000);
    }
    function isoWeek(d) {
        var t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        var day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        var ys = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil((((t - ys) / 86400000) + 1) / 7);
    }
    function uptimeStr(s) {
        var d = Math.floor(s / 86400);
        var h = Math.floor((s % 86400) / 3600);
        var m = Math.floor((s % 3600) / 60);
        return (d > 0 ? d + "d " : "") + p2(h) + ":" + p2(m);
    }

    readonly property bool h24: plasmoid.configuration.use24h
    readonly property int hr: now.getHours()
    readonly property string timeStr: (h24 ? p2(hr) : p2(((hr % 12) || 12))) + ":" + p2(now.getMinutes())
    readonly property string ampm: hr < 12 ? "AM" : "PM"
    readonly property string secStr: p2(now.getSeconds())
    readonly property var weekdays: ["SUN","MON","TUE","WED","THU","FRI","SAT"]
    readonly property var months: ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"]
    readonly property string dateStr: weekdays[now.getDay()] + " " + p2(now.getDate()) + " " + months[now.getMonth()] + " " + now.getFullYear()
    readonly property int doy: dayOfYear(now)
    readonly property int diy: daysInYear(now.getFullYear())
    readonly property real yearFrac: doy / diy
    readonly property int unixT: Math.floor(now.getTime() / 1000)

    // ---- compact (panel) --------------------------------------------------
    compactRepresentation: RowLayout {
        spacing: Lattice.Theme.sm
        Lattice.MonoText {
            text: root.timeStr
            tone: Lattice.Theme.ink
            font.pixelSize: Lattice.Theme.fsBody
        }
        Lattice.MonoText {
            text: "W" + root.isoWeek(root.now)
            tone: root.accent
            font.pixelSize: Lattice.Theme.fsMicro
        }
        MouseArea { anchors.fill: parent; onClicked: root.expanded = !root.expanded }
    }

    // ---- full (desktop) ---------------------------------------------------
    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 13
        implicitWidth: Kirigami.Units.gridUnit * 15
        implicitHeight: col.implicitHeight + Lattice.Theme.md * 2

        Lattice.Scrim { anchors.fill: parent; strength: root.scrim }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: Lattice.Theme.md
            spacing: Lattice.Theme.sm

            RowLayout {
                Layout.fillWidth: true
                Lattice.Caption { text: "epoch"; tone: Lattice.Theme.faint }
                Item { Layout.fillWidth: true }
                Lattice.Caption {
                    text: Qt.formatDateTime(root.now, "t")  // tz abbrev
                    tone: Lattice.Theme.faint
                    font.pixelSize: Lattice.Theme.fsMicro
                }
            }

            // big time
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Lattice.Theme.xs
                spacing: Lattice.Theme.sm
                Lattice.MonoText {
                    text: root.timeStr
                    tone: Lattice.Theme.ink
                    font.pixelSize: Lattice.Theme.fsHero
                    font.weight: Font.DemiBold
                }
                ColumnLayout {
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: Lattice.Theme.xs
                    spacing: 0
                    Lattice.MonoText {
                        visible: plasmoid.configuration.showSeconds
                        text: ":" + root.secStr
                        tone: root.accent
                        font.pixelSize: Lattice.Theme.fsReadout
                    }
                    Lattice.Caption {
                        visible: !root.h24
                        text: root.ampm
                        tone: Lattice.Theme.faint
                    }
                }
                Item { Layout.fillWidth: true }
            }

            Lattice.MonoText {
                text: root.dateStr
                tone: Lattice.Theme.dim
                font.pixelSize: Lattice.Theme.fsCaption
                font.letterSpacing: 1.5
            }

            Lattice.Hairline { Layout.fillWidth: true; Layout.topMargin: Lattice.Theme.xs; Layout.bottomMargin: Lattice.Theme.xs }

            // niche grid
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: Lattice.Theme.lg
                rowSpacing: Lattice.Theme.sm

                ColumnLayout {
                    spacing: 0
                    Lattice.Caption { text: "iso week" }
                    Lattice.MonoText { text: "W" + root.isoWeek(root.now); tone: Lattice.Theme.ink; font.pixelSize: Lattice.Theme.fsReadout }
                }
                ColumnLayout {
                    spacing: 0
                    Lattice.Caption { text: "day of year"; Layout.alignment: Qt.AlignRight }
                    Lattice.MonoText {
                        Layout.alignment: Qt.AlignRight
                        text: root.doy + " / " + root.diy
                        tone: Lattice.Theme.ink; font.pixelSize: Lattice.Theme.fsReadout
                    }
                }
            }

            // year progress hairline
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Lattice.Theme.xs
                spacing: 2
                RowLayout {
                    Layout.fillWidth: true
                    Lattice.Caption { text: "year"; tone: Lattice.Theme.faint }
                    Item { Layout.fillWidth: true }
                    Lattice.MonoText { text: Math.round(root.yearFrac * 100) + "%"; tone: Lattice.Theme.dim; font.pixelSize: Lattice.Theme.fsMicro }
                }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: Lattice.Theme.xs
                    Rectangle { anchors.fill: parent; color: Lattice.Theme.wash }
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: parent.width * root.yearFrac
                        color: root.accent; opacity: 0.85
                        Behavior on width { NumberAnimation { duration: Lattice.Theme.tMed } }
                    }
                }
            }

            Lattice.Hairline { Layout.fillWidth: true; Layout.topMargin: Lattice.Theme.xs; Layout.bottomMargin: Lattice.Theme.xs }

            // epoch + uptime readouts
            RowLayout {
                Layout.fillWidth: true
                visible: plasmoid.configuration.showEpoch
                Lattice.Caption { text: "unix" }
                Item { Layout.fillWidth: true }
                Lattice.MonoText { text: root.unixT; tone: root.accent; font.pixelSize: Lattice.Theme.fsCaption }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: plasmoid.configuration.showUptime
                Lattice.Caption { text: "uptime" }
                Item { Layout.fillWidth: true }
                Lattice.MonoText { text: root.uptimeStr(root.uptimeSecs); tone: Lattice.Theme.dim; font.pixelSize: Lattice.Theme.fsCaption }
            }
        }
    }
}
