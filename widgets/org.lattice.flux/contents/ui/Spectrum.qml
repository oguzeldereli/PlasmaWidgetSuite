import QtQuick
import "lattice" as Lattice

/*
 * A quiet spectrum. Not a real FFT — each bar wanders on its own gentle
 * timer so it feels alive while playing, and settles flat when paused.
 */
Row {
    id: root
    property bool active: false
    property color tone: Lattice.Theme.accentDefault
    property int bars: 7
    spacing: Math.max(1, Lattice.Theme.hair * 2)

    Repeater {
        model: root.bars
        delegate: Rectangle {
            id: bar
            width: Math.max(2, (root.width - root.spacing * (root.bars - 1)) / root.bars)
            anchors.bottom: parent.bottom
            property real level: 0.1
            height: Math.max(root.height * 0.06, root.height * level)
            radius: width / 2
            color: root.tone
            opacity: 0.45 + level * 0.5
            antialiasing: true

            Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 240 } }

            Timer {
                interval: 180 + Math.round(Math.random() * 260)
                running: true; repeat: true
                onTriggered: bar.level = root.active ? (0.2 + Math.random() * 0.8) : 0.08
            }
        }
    }
}
