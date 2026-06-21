import QtQuick
import QtQuick.Layouts
import "." as Lattice

/* A single adaptive hairline. Horizontal by default. */
Rectangle {
    id: root
    property bool vertical: false
    property color tone: Lattice.Theme.ghost
    color: tone
    implicitWidth: vertical ? Lattice.Theme.hair : 100
    implicitHeight: vertical ? 100 : Lattice.Theme.hair
    Layout.fillWidth: !vertical
    Layout.fillHeight: vertical
    antialiasing: false
}
