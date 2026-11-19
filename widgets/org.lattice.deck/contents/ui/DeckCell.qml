import QtQuick
import org.kde.kirigami as Kirigami
import "lattice" as Lattice

/*
 * One window on the tape. At rest: an app icon over a short hairline tick.
 * Active: the tick lights accent across the whole cell and the title slides
 * open. Hover: same reveal. Demands-attention: the tick pulses in warn.
 * Press-and-drag reorders the cell along the tape (see main.qml dragOver).
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
    property int itemIndex: -1        // row in the tasks model (for reordering)

    signal leftClicked()
    signal middleClicked()
    signal rightClicked()
    signal dragStarted()
    signal dragMoved(real mx, real my)  // pointer, in this cell's coordinates
    signal dragEnded()

    readonly property bool dragging: mouse.dragging
    readonly property bool open: active || mouse.containsMouse || alwaysLabel || dragging
    readonly property int padH: Lattice.Theme.sm

    // Target (non-animated) geometry, so the tape can size itself from the
    // resting state and never re-centre because a hovered label slid open.
    readonly property real labelFull: Math.min(labelText.implicitWidth, Kirigami.Units.gridUnit * 9)
    readonly property real labelSpan: labelFull > 0 ? labelFull + Lattice.Theme.xs : 0
    readonly property bool restOpen: active || alwaysLabel
    readonly property real restWidth: padH * 2 + iconPx + (restOpen ? labelSpan : 0)
    readonly property real hoverGrow: restOpen ? 0 : labelSpan

    implicitHeight: iconPx + Lattice.Theme.sm * 2
    implicitWidth: padH + iconPx + labelWrap.width + (labelWrap.width > 0 ? Lattice.Theme.xs : 0) + padH
    Behavior on implicitWidth { NumberAnimation { duration: Lattice.Theme.tFast; easing.type: Lattice.Theme.easing } }

    // hover wash
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        color: mouse.dragging ? Lattice.Theme.fg(0.10)
             : mouse.containsMouse ? Lattice.Theme.fg(0.05) : "transparent"
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

        // stepped blink (2 redraws/s) instead of a tween that repaints every vsync
        Timer {
            interval: 500; running: cell.attention; repeat: true
            onTriggered: base.opacity = base.opacity > 0.5 ? 0.25 : 1.0
            onRunningChanged: if (!running) base.opacity = 1.0
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        property bool dragging: false
        property bool wasDrag: false      // swallow the click that ends a drag
        property real pressX: 0
        property real pressY: 0

        function endDrag() {
            if (!dragging) return;
            dragging = false;
            cell.dragEnded();
        }

        onPressed: (m) => { wasDrag = false; pressX = m.x; pressY = m.y; }
        onPositionChanged: (m) => {
            if (!(pressedButtons & Qt.LeftButton)) return;
            if (!dragging) {
                var d = Qt.styleHints.startDragDistance;
                if (Math.abs(m.x - pressX) < d && Math.abs(m.y - pressY) < d) return;
                dragging = true;
                wasDrag = true;
                cell.dragStarted();
            }
            cell.dragMoved(m.x, m.y);
        }
        onReleased: endDrag()
        onCanceled: endDrag()
        onClicked: (m) => {
            if (wasDrag) { wasDrag = false; return; }
            if (m.button === Qt.MiddleButton) cell.middleClicked();
            else if (m.button === Qt.RightButton) cell.rightClicked();
            else cell.leftClicked();
        }
    }
}
