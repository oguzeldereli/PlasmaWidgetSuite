import QtQuick
import QtQuick.Layouts
import "." as Lattice

/*
 * A horizontal instrument meter:
 *
 *   LABEL                       12.4 GB
 *   ┌──────────────────────────────────┐
 *   ▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░  (ticked track)
 *
 * value/max drives the fill. Optional level colouring tints the fill
 * amber/red as it approaches max (good for VRAM, temps, disk).
 */
ColumnLayout {
    id: root
    spacing: Lattice.Theme.xs

    property string label: ""
    property real value: 0
    property real max: 100
    property string valueText: ""           // overrides the numeric readout
    property color accent: Lattice.Theme.accentDefault
    property bool colorByLevel: false
    property real barHeight: Math.round(Lattice.Theme.sm * 1.1)

    readonly property real ratio: max > 0 ? Math.max(0, Math.min(value / max, 1)) : 0
    readonly property color fillColor: {
        if (!colorByLevel) return accent;
        if (ratio > 0.88) return Lattice.Theme.hot;
        if (ratio > 0.70) return Lattice.Theme.warn;
        return accent;
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Lattice.Theme.sm
        Lattice.Caption {
            text: root.label
            Layout.fillWidth: true
        }
        Lattice.MonoText {
            text: root.valueText !== "" ? root.valueText : Math.round(root.value)
            font.pixelSize: Lattice.Theme.fsCaption
            tone: Lattice.Theme.ink
        }
    }

    Item {
        id: track
        Layout.fillWidth: true
        implicitHeight: root.barHeight

        // recessed track
        Rectangle {
            anchors.fill: parent
            color: Lattice.Theme.wash
            border.width: Lattice.Theme.hair
            border.color: Lattice.Theme.ghost
            radius: 0
        }

        // fill
        Rectangle {
            id: fill
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: Math.round(parent.width * root.ratio)
            color: root.fillColor
            opacity: 0.85
            Behavior on width { NumberAnimation { duration: Lattice.Theme.tMed; easing.type: Lattice.Theme.easing } }
            Behavior on color { ColorAnimation { duration: Lattice.Theme.tMed } }
        }

        // tick overlay
        Lattice.Ticks {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height
            count: 32
            major: 8
            tone: Lattice.Theme.fg(0.10)
        }
    }
}
