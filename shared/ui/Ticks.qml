import QtQuick
import "." as Lattice

/*
 * A horizontal ruler of tick marks — the recurring instrument motif.
 * Every `major`-th tick is taller. Ticks hang from the top edge.
 */
Canvas {
    id: root
    property int count: 24
    property int major: 6
    property color tone: Lattice.Theme.ghost
    property real minorLen: height * 0.42
    property real majorLen: height
    implicitHeight: Lattice.Theme.sm

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onToneChanged: requestPaint()
    onCountChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = tone;
        ctx.lineWidth = Lattice.Theme.hair;
        const n = Math.max(1, count);
        for (let i = 0; i <= n; i++) {
            const x = Math.round((width - Lattice.Theme.hair) * (i / n)) + 0.5;
            const len = (i % major === 0) ? majorLen : minorLen;
            ctx.beginPath();
            ctx.moveTo(x, 0);
            ctx.lineTo(x, len);
            ctx.stroke();
        }
    }
}
