import QtQuick
import org.kde.kirigami as Kirigami
import "." as Lattice

/*
 * Adaptive legibility scrim. Tinted with the scheme background so it
 * reads correctly on light or dark wallpapers. `strength` 0 => fully
 * floating (no backing); higher values add a frosted plate for busy
 * wallpapers. A single hairline keeps the instrument edge crisp.
 */
Rectangle {
    id: root
    property real strength: 0.0
    color: Lattice.Theme.alpha(Kirigami.Theme.backgroundColor, strength * 0.82)
    radius: Lattice.Theme.xs
    border.width: strength > 0.02 ? Lattice.Theme.hair : 0
    border.color: Lattice.Theme.fg(0.12 + strength * 0.10)

    // barely-there top sheen for a sense of material, only when visible
    Rectangle {
        visible: root.strength > 0.02
        anchors { left: parent.left; right: parent.right; top: parent.top }
        anchors.margins: root.radius
        height: Lattice.Theme.hair
        color: Lattice.Theme.fg(0.06)
    }
}
