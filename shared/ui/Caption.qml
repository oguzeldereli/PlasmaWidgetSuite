import QtQuick
import "." as Lattice

/* A quiet, letter-spaced small-caps label — the "instrument" tag. */
Text {
    id: root
    property color tone: Lattice.Theme.dim
    font.family: Lattice.Theme.sans
    font.pixelSize: Lattice.Theme.fsCaption
    font.weight: Font.Medium
    font.capitalization: Font.AllUppercase
    font.letterSpacing: Lattice.Theme.caps
    color: tone
    renderType: Text.NativeRendering
    elide: Text.ElideRight
    textFormat: Text.PlainText
}
