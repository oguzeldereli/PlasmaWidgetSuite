import QtQuick
import "lattice" as Lattice

/*
 * One launcher cell. At rest: just the glyph. On hover: accent tint, an
 * underline grows, and the label slides open. A leading hairline divides
 * it from the previous cell.
 */
Item {
    id: cell
    property string glyph: ""
    property string label: ""
    property real glyphPx: Lattice.Theme.fsReadout
    property color accent: Lattice.Theme.accentDefault
    property bool alwaysLabel: false
    property bool first: false

    signal activated()

    readonly property bool open: hov.hovered || alwaysLabel
    readonly property int padH: Lattice.Theme.md

    implicitHeight: Math.max(glyphPx, Lattice.Theme.lg) + Lattice.Theme.sm * 2
    implicitWidth: padH + glyphItem.implicitWidth + labelWrap.width + (labelWrap.width > 0 ? Lattice.Theme.sm : 0) + padH

    Behavior on implicitWidth { NumberAnimation { duration: Lattice.Theme.tFast; easing.type: Lattice.Theme.easing } }

    HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: cell.activated() }

    // leading separator
    Rectangle {
        visible: !cell.first
        width: Lattice.Theme.hair
        height: parent.height * 0.5
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: Lattice.Theme.ghost
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        x: cell.padH
        spacing: Lattice.Theme.sm

        Lattice.MonoText {
            id: glyphItem
            text: cell.glyph
            font.pixelSize: cell.glyphPx
            tone: cell.open ? cell.accent : Lattice.Theme.dim
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: Lattice.Theme.tFast } }
        }

        Item {
            id: labelWrap
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            height: labelText.implicitHeight
            width: cell.open ? labelText.implicitWidth : 0
            opacity: cell.open ? 1 : 0
            Behavior on width { NumberAnimation { duration: Lattice.Theme.tFast; easing.type: Lattice.Theme.easing } }
            Behavior on opacity { NumberAnimation { duration: Lattice.Theme.tFast } }
            Lattice.MonoText {
                id: labelText
                text: cell.label
                font.pixelSize: Lattice.Theme.fsCaption
                tone: Lattice.Theme.ink
            }
        }
    }

    // hover underline
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height: Lattice.Theme.hair * 2
        width: cell.open ? parent.width - cell.padH : 0
        color: cell.accent
        Behavior on width { NumberAnimation { duration: Lattice.Theme.tFast; easing.type: Lattice.Theme.easing } }
    }
}
