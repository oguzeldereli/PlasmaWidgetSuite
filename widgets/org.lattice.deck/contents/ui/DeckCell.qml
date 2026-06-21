import QtQuick
import org.kde.kirigami as Kirigami
import "lattice" as Lattice

/*
 * One window on the tape. At rest: an app icon over a short hairline tick.
 * Active: the tick lights accent across the whole cell and the title slides
 * open. Hover: same reveal. Demands-attention: the tick pulses in warn.
 */
Item {
    id: cell
    property var iconSource
    property string title: ""
    property bool active: false
    property bool minimized: false
    property bool attention: false
    property bool mono: false
    property bool alwaysLabel: false
    property bool first: false
    property bool isLauncher: false   // pinned app, not currently running
    property bool pinned: false       // running window that is also pinned
    property real iconPx: Lattice.Theme.lg
    property color accent: Lattice.Theme.accentDefault

    signal leftClicked()
    signal middleClicked()
    signal rightClicked()

    readonly property bool open: active || mouse.containsMouse || alwaysLabel
    readonly property int padH: Lattice.Theme.sm

    implicitHeight: iconPx + Lattice.Theme.sm * 2
    implicitWidth: padH + iconPx + labelWrap.width + (labelWrap.width > 0 ? Lattice.Theme.xs : 0) + padH
    Behavior on implicitWidth { NumberAnimation { duration: Lattice.Theme.tFast; easing.type: Lattice.Theme.easing } }

    // hover wash
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        color: mouse.containsMouse ? Lattice.Theme.fg(0.05) : "transparent"
        radius: Lattice.Theme.xs
    }

    // leading separator
    Rectangle {
        visible: !cell.first
        width: Lattice.Theme.hair
        height: parent.height * 0.45
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: Lattice.Theme.ghost
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        x: cell.padH
        spacing: Lattice.Theme.xs

        Kirigami.Icon {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            source: cell.iconSource
            implicitWidth: cell.iconPx
            implicitHeight: cell.iconPx
            isMask: cell.mono && !cell.open
            color: Lattice.Theme.dim
            opacity: (cell.minimized && !cell.open) ? 0.4
                   : (cell.isLauncher && !cell.open) ? 0.7 : 1.0
            Behavior on opacity { NumberAnimation { duration: Lattice.Theme.tFast } }
        }

        Item {
            id: labelWrap
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            height: labelText.implicitHeight
            width: cell.open ? Math.min(labelText.implicitWidth, Kirigami.Units.gridUnit * 9) : 0
            opacity: cell.open ? 1 : 0
            Behavior on width { NumberAnimation { duration: Lattice.Theme.tFast; easing.type: Lattice.Theme.easing } }
            Behavior on opacity { NumberAnimation { duration: Lattice.Theme.tFast } }
            Lattice.MonoText {
                id: labelText
                width: parent.width
                text: cell.title
                font.pixelSize: Lattice.Theme.fsCaption
                tone: cell.active ? Lattice.Theme.ink : Lattice.Theme.dim
            }
        }
    }

    // baseline tick / lit segment
    Rectangle {
        id: base
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        height: cell.active ? Lattice.Theme.hair * 2 : Lattice.Theme.hair
        width: cell.open ? parent.width - cell.padH : cell.iconPx
        color: cell.attention ? Lattice.Theme.warn
             : cell.active ? cell.accent
             : cell.isLauncher ? Lattice.Theme.fg(0.16)
             : cell.minimized ? Lattice.Theme.faint : Lattice.Theme.ghost
        Behavior on width { NumberAnimation { duration: Lattice.Theme.tFast; easing.type: Lattice.Theme.easing } }
        Behavior on color { ColorAnimation { duration: Lattice.Theme.tFast } }

        SequentialAnimation on opacity {
            running: cell.attention; loops: Animation.Infinite; alwaysRunToEnd: true
            NumberAnimation { from: 1.0; to: 0.25; duration: 500 }
            NumberAnimation { from: 0.25; to: 1.0; duration: 500 }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: (m) => {
            if (m.button === Qt.MiddleButton) cell.middleClicked();
            else if (m.button === Qt.RightButton) cell.rightClicked();
            else cell.leftClicked();
        }
    }
}
