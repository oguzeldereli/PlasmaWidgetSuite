// Remove the Lattice top bar created by top-bar.js.
(function () {
    var ps = panels();
    for (var i = 0; i < ps.length; i++) {
        if (ps[i].location !== "top") continue;
        var ws = ps[i].widgets();
        for (var j = 0; j < ws.length; j++) {
            if (ws[j].type === "org.lattice.rail" || ws[j].type === "org.lattice.deck"
                || ws[j].type === "org.kde.plasma.appmenu") {
                ps[i].remove();
                break;
            }
        }
    }
})();
