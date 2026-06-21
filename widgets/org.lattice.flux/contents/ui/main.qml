import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import "lattice" as Lattice

PlasmoidItem {
    id: root

    readonly property color accent: plasmoid.configuration.accentColor.length > 0
        ? plasmoid.configuration.accentColor : Lattice.Theme.accentDefault
    readonly property real scrim: plasmoid.configuration.scrimStrength

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    Mpris.Mpris2Model { id: mprisModel }

    readonly property var player: mprisModel.currentPlayer
    readonly property bool hasPlayer: player !== null && player !== undefined
    readonly property bool playing: hasPlayer && player.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property string title: hasPlayer && player.track ? player.track : ""
    readonly property string artist: hasPlayer && player.artist ? player.artist : ""
    readonly property string album: hasPlayer && player.album ? player.album : ""
    readonly property string artUrl: hasPlayer && player.artUrl ? player.artUrl : ""
    readonly property real progress: (hasPlayer && player.length > 0) ? player.position / player.length : 0

    function p2(n) { return (n < 10 ? "0" : "") + n; }
    function tStr(us) {
        if (!us || us < 0) return "0:00";
        var s = Math.floor(us / 1000000);
        return Math.floor(s / 60) + ":" + p2(s % 60);
    }

    Timer {
        interval: 1000; running: root.playing; repeat: true
        onTriggered: if (root.hasPlayer) root.player.updatePosition()
    }

    // ---- compact ----------------------------------------------------------
    compactRepresentation: RowLayout {
        spacing: Lattice.Theme.xs
        Lattice.MonoText {
            text: root.playing ? String.fromCharCode(0xf04b) : String.fromCharCode(0xf04c)   // play/pause status
            tone: root.accent
            font.pixelSize: Lattice.Theme.fsCaption
        }
        Lattice.MonoText {
            text: root.hasPlayer ? root.title : "—"
            tone: Lattice.Theme.dim
            font.pixelSize: Lattice.Theme.fsCaption
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
        }
        MouseArea { anchors.fill: parent; onClicked: root.expanded = !root.expanded }
    }

    // ---- full -------------------------------------------------------------
    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        implicitWidth: Kirigami.Units.gridUnit * 16
        implicitHeight: col.implicitHeight + Lattice.Theme.md * 2
        clip: true

        // faint album-art backdrop (optional)
        Image {
            anchors.fill: parent
            source: plasmoid.configuration.artBackdrop ? root.artUrl : ""
            fillMode: Image.PreserveAspectCrop
            opacity: (plasmoid.configuration.artBackdrop && root.artUrl !== "") ? 0.16 : 0
            asynchronous: true
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Lattice.Theme.tSlow } }
        }
        Lattice.Scrim { anchors.fill: parent; strength: root.scrim }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: Lattice.Theme.md
            spacing: Lattice.Theme.sm

            RowLayout {
                Layout.fillWidth: true
                Lattice.Caption { text: "flux" }
                Item { Layout.fillWidth: true }
                Lattice.MonoText {
                    text: root.hasPlayer && root.player.identity ? root.player.identity : ""
                    tone: Lattice.Theme.faint; font.pixelSize: Lattice.Theme.fsMicro
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 8
                }
            }
            Lattice.Hairline { Layout.fillWidth: true }

            // art + title block
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Lattice.Theme.xs
                spacing: Lattice.Theme.md

                Item {
                    visible: plasmoid.configuration.showArt
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3.2
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3.2
                    clip: true
                    Rectangle { anchors.fill: parent; color: Lattice.Theme.wash; radius: Lattice.Theme.xs }
                    Image {
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: root.artUrl !== ""
                    }
                    Lattice.MonoText {
                        anchors.centerIn: parent
                        visible: root.artUrl === ""
                        text: String.fromCharCode(0xf001)   // music note
                        tone: Lattice.Theme.faint
                        font.pixelSize: Lattice.Theme.fsReadout
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        radius: Lattice.Theme.xs
                        border.width: Lattice.Theme.hair
                        border.color: Lattice.Theme.ghost
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Lattice.MonoText {
                        Layout.fillWidth: true
                        text: root.hasPlayer ? root.title : "nothing playing"
                        tone: root.hasPlayer ? Lattice.Theme.ink : Lattice.Theme.faint
                        font.pixelSize: Lattice.Theme.fsBody
                        font.weight: Font.DemiBold
                    }
                    Lattice.MonoText {
                        Layout.fillWidth: true
                        visible: root.artist !== ""
                        text: root.artist
                        tone: Lattice.Theme.dim
                        font.pixelSize: Lattice.Theme.fsCaption
                    }
                    Lattice.MonoText {
                        Layout.fillWidth: true
                        visible: root.album !== ""
                        text: root.album
                        tone: Lattice.Theme.faint
                        font.pixelSize: Lattice.Theme.fsMicro
                    }
                }
            }

            // seek
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Lattice.Theme.xs
                spacing: 3
                visible: root.hasPlayer
                Item {
                    Layout.fillWidth: true
                    implicitHeight: Lattice.Theme.xs
                    Rectangle { anchors.fill: parent; color: Lattice.Theme.wash }
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: parent.width * root.progress
                        color: root.accent; opacity: 0.9
                        Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.hasPlayer && root.player.canSeek
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: (m) => {
                            if (!root.hasPlayer || root.player.length <= 0) return;
                            var target = (m.x / width) * root.player.length;
                            root.player.Seek(target - root.player.position);
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Lattice.MonoText { text: root.tStr(root.hasPlayer ? root.player.position : 0); tone: Lattice.Theme.dim; font.pixelSize: Lattice.Theme.fsMicro }
                    Item { Layout.fillWidth: true }
                    Lattice.MonoText { text: root.tStr(root.hasPlayer ? root.player.length : 0); tone: Lattice.Theme.faint; font.pixelSize: Lattice.Theme.fsMicro }
                }
            }

            // controls + spectrum
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Lattice.Theme.xs
                spacing: Lattice.Theme.md

                Row {
                    spacing: Lattice.Theme.md
                    Lattice.MonoText {
                        text: String.fromCharCode(0xf048)   // prev
                        tone: (root.hasPlayer && root.player.canGoPrevious) ? Lattice.Theme.ink : Lattice.Theme.faint
                        font.pixelSize: Lattice.Theme.fsReadout
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            enabled: root.hasPlayer && root.player.canGoPrevious
                            onClicked: root.player.Previous()
                        }
                    }
                    Lattice.MonoText {
                        text: root.playing ? String.fromCharCode(0xf04c) : String.fromCharCode(0xf04b)   // pause when playing
                        tone: root.accent
                        font.pixelSize: Lattice.Theme.fsReadout
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            enabled: root.hasPlayer
                            onClicked: root.player.PlayPause()
                        }
                    }
                    Lattice.MonoText {
                        text: String.fromCharCode(0xf051)   // next
                        tone: (root.hasPlayer && root.player.canGoNext) ? Lattice.Theme.ink : Lattice.Theme.faint
                        font.pixelSize: Lattice.Theme.fsReadout
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            enabled: root.hasPlayer && root.player.canGoNext
                            onClicked: root.player.Next()
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Spectrum {
                    visible: plasmoid.configuration.showSpectrum
                    active: root.playing
                    tone: root.accent
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.4
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}
