import QtQuick
import "." as Lattice

/*
 * A minimalist sparkline. Feed it `values` (numbers); it scales to
 * `maxValue` (or auto-max when 0). Crisp segments, faint area wash.
 */
Canvas {
    id: root
    property var values: []
    property real maxValue: 100        // 0 => autoscale
    property color line: Lattice.Theme.accentDefault
    property bool fill: true
    property real lineWidth: Lattice.Theme.hair * 1.5
    property bool showBaseline: true   // faint zero rule

    onValuesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onLineChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const n = values ? values.length : 0;
        const w = width, h = height;

        if (showBaseline) {
            ctx.strokeStyle = Lattice.Theme.ghost;
            ctx.lineWidth = Lattice.Theme.hair;
            ctx.beginPath();
            ctx.moveTo(0, h - 0.5);
            ctx.lineTo(w, h - 0.5);
            ctx.stroke();
        }
        if (n < 2) return;

        let peak = maxValue;
        if (peak <= 0) { peak = 1; for (let i = 0; i < n; i++) peak = Math.max(peak, values[i]); }

        const pad = lineWidth;
        const stepX = w / (n - 1);
        const yOf = v => h - pad - (Math.max(0, Math.min(v, peak)) / peak) * (h - pad * 2);

        // area wash
        if (fill) {
            const grad = ctx.createLinearGradient(0, 0, 0, h);
            grad.addColorStop(0, Lattice.Theme.alpha(line, 0.22));
            grad.addColorStop(1, Lattice.Theme.alpha(line, 0.0));
            ctx.fillStyle = grad;
            ctx.beginPath();
            ctx.moveTo(0, h);
            for (let i = 0; i < n; i++) ctx.lineTo(i * stepX, yOf(values[i]));
            ctx.lineTo(w, h);
            ctx.closePath();
            ctx.fill();
        }

        // line
        ctx.strokeStyle = line;
        ctx.lineWidth = lineWidth;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.beginPath();
        for (let i = 0; i < n; i++) {
            const x = i * stepX, y = yOf(values[i]);
            i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
        }
        ctx.stroke();

        // leading dot
        ctx.fillStyle = line;
        const lx = (n - 1) * stepX, ly = yOf(values[n - 1]);
        ctx.beginPath();
        ctx.arc(lx, ly, lineWidth * 1.4, 0, Math.PI * 2);
        ctx.fill();
    }
}
