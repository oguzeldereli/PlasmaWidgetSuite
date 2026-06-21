import QtQuick
import "." as Lattice

/* Monospace numerals/data with tabular figures. */
Text {
    id: root
    property color tone: Lattice.Theme.ink
    font.family: Lattice.Theme.mono
    font.pixelSize: Lattice.Theme.fsBody
    // Tabular, lining figures so columns of numbers don't jitter.
    font.features: { "tnum": 1, "lnum": 1 }
    color: tone
    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    elide: Text.ElideRight
}
