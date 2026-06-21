/*
 * Lattice Deck Navigation — traverse application windows along the bar.
 *
 * Works on Wayland and X11 (runs inside KWin). Registers two global shortcuts;
 * activating one focuses the next/previous window AND un-minimises it so it
 * actually comes forward (plain focus does nothing to a minimised window).
 *
 * Order is tracked by window creation (like the Deck / taskbar) and kept stable
 * — KWin's live windowList() reorders on activation, which would make next/prev
 * jump around, so we maintain our own stable order instead.
 *
 * Debug:  journalctl -b -f | grep -i "lattice-deck:"
 */

// Set true to also maximise the target window when you land on it.
const FORCE_MAXIMIZE = false;

function log(m) { console.info("lattice-deck: " + m); }
function wid(w) { return "" + w.internalId; }

// Stable creation order of window ids.
var order = workspace.windowList().map(wid);
workspace.windowAdded.connect(function (w) {
    if (order.indexOf(wid(w)) < 0) order.push(wid(w));
});
workspace.windowRemoved.connect(function (w) {
    var i = order.indexOf(wid(w));
    if (i >= 0) order.splice(i, 1);
});

function eligible(w) {
    return w && w.normalWindow && !w.skipTaskbar && !w.skipSwitcher;
}

// Eligible windows in stable order.
function tabList() {
    var all = workspace.windowList();
    var byId = {};
    for (var i = 0; i < all.length; i++) {
        var id = wid(all[i]);
        byId[id] = all[i];
        if (order.indexOf(id) < 0) order.push(id);   // pick up anything missed
    }
    var wins = [];
    for (var j = 0; j < order.length; j++) {
        var w = byId[order[j]];
        if (eligible(w)) wins.push(w);
    }
    return wins;
}

function go(step) {
    var wins = tabList();
    if (wins.length === 0) return;

    var active = workspace.activeWindow;
    var idx = -1;
    if (active) {
        var aid = wid(active);
        for (var i = 0; i < wins.length; i++) {
            if (wid(wins[i]) === aid) { idx = i; break; }
        }
    }

    var target;
    if (idx < 0) target = (step > 0) ? 0 : wins.length - 1;
    else target = (idx + step + wins.length) % wins.length;

    var w = wins[target];
    if (w.minimized) w.minimized = false;
    if (FORCE_MAXIMIZE && typeof w.setMaximize === "function") w.setMaximize(true, true);
    workspace.activeWindow = w;

    log("focus " + (target + 1) + "/" + wins.length + " — " + w.caption);
}

registerShortcut("Lattice Deck Next Window",     "Lattice Deck: Next Window",     "Meta+]", function () { go(1); });
registerShortcut("Lattice Deck Previous Window", "Lattice Deck: Previous Window", "Meta+[", function () { go(-1); });

log("loaded; shortcuts Meta+] / Meta+[ registered");
