// Lattice top bar — a slim global-menu panel.
// Idempotent: removes any previous Lattice top bar (identified by containing
// org.lattice.rail) before creating a fresh one. Safe to re-run.

(function () {
    var existing = panels();
    for (var i = 0; i < existing.length; i++) {
        var ws = existing[i].widgets();
        for (var j = 0; j < ws.length; j++) {
            if (ws[j].type === "org.lattice.rail" || ws[j].type === "org.kde.plasma.appmenu") {
                if (existing[i].location === "top") { existing[i].remove(); break; }
            }
        }
    }

    function expandingSpacer(panel) {
        var s = panel.addWidget("org.kde.plasma.panelspacer");
        if (s) {
            s.currentConfigGroup = ["General"];
            try { s.writeConfig("expanding", true); } catch (e) {}
            s.reloadConfig();
        }
        return s;
    }

    var p = new Panel;
    p.location = "top";
    p.height = 36;
    p.hiding = "none";
    p.floating = false;

    // [ launcher ] [ global menu ]  ·····  [ task tape ]  ·····  [ rail ] [ clock ] [ bell ]

    // App launcher bound to the Super/Meta key. Full-screen launcher => always
    // opens centered (fixes the orphaned "activate application launcher" that
    // was popping up in the top-left corner).
    var launcher = p.addWidget("org.kde.plasma.kickerdash");
    if (launcher) {
        try { launcher.globalShortcut = "Meta"; } catch (e) {}
    }

    p.addWidget("org.kde.plasma.appmenu");
    expandingSpacer(p);
    p.addWidget("org.lattice.deck");
    expandingSpacer(p);
    p.addWidget("org.lattice.rail");
    p.addWidget("org.lattice.epoch");

    // Notification server. Plasma's org.freedesktop.Notifications lives in this
    // applet (normally inside the system tray). With no tray on this bar, nothing
    // serves notifications: D-Bus activation waits 60 s and fails, and apps that
    // notify synchronously (Electron/libnotify, e.g. Discord) freeze meanwhile.
    p.addWidget("org.kde.plasma.notifications");
})();
