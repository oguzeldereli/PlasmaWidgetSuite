import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "lattice" as Lattice

PlasmoidItem {
    id: root

    readonly property color accent: plasmoid.configuration.accentColor.length > 0
        ? plasmoid.configuration.accentColor : Lattice.Theme.accentDefault
    readonly property real scrim: plasmoid.configuration.scrimStrength

    property var repos: []   // [{path,branch,dirty,ahead,behind,type,ok}]

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    function paths() {
        return plasmoid.configuration.repos.split("\n")
            .map(function (s) { return s.trim(); })
            .filter(function (s) { return s.length > 0; });
    }
    function shQuote(p) {
        if (p === "~") return '"$HOME"';
        if (p.indexOf("~/") === 0) return '"$HOME/' + p.slice(2).replace(/"/g, '\\"') + '"';
        return '"' + p.replace(/"/g, '\\"') + '"';
    }
    function baseName(p) {
        var parts = p.split("/").filter(function (s) { return s.length > 0; });
        return parts.length ? parts[parts.length - 1] : p;
    }

    P5Support.DataSource {
        id: scanner
        engine: "executable"
        connectedSources: []
        onNewData: (s, d) => { disconnectSource(s); root.parse(d["stdout"] || ""); }
        function scan() {
            var ps = root.paths();
            if (ps.length === 0) { root.repos = []; return; }
            var list = ps.map(root.shQuote).join(" ");
            var sh =
                'for d in ' + list + '; do ' +
                  'if git -C "$d" rev-parse --git-dir >/dev/null 2>&1; then ' +
                    'b=$(git -C "$d" rev-parse --abbrev-ref HEAD 2>/dev/null); ' +
                    'dirty=$(git -C "$d" status --porcelain 2>/dev/null | wc -l | tr -d " "); ' +
                    'ahead=$(git -C "$d" rev-list --count "@{u}"..HEAD 2>/dev/null || echo 0); ' +
                    'behind=$(git -C "$d" rev-list --count HEAD.."@{u}" 2>/dev/null || echo 0); ' +
                    't=GIT; ' +
                    'if ls "$d"/*.sln "$d"/*.csproj >/dev/null 2>&1; then t=NET; ' +
                    'elif [ -f "$d/package.json" ]; then t=NODE; ' +
                    'elif [ -f "$d/pyproject.toml" ] || [ -f "$d/requirements.txt" ] || [ -f "$d/setup.py" ]; then t=PY; ' +
                    'elif [ -f "$d/Cargo.toml" ]; then t=RS; ' +
                    'elif [ -f "$d/go.mod" ]; then t=GO; ' +
                    'elif [ -f "$d/CMakeLists.txt" ] || ls "$d"/*.cpp "$d"/*.c >/dev/null 2>&1; then t=CPP; fi; ' +
                    'echo "$d|$b|${dirty:-0}|${ahead:-0}|${behind:-0}|$t"; ' +
                  'else echo "$d|!|0|0|0|NONE"; fi; ' +
                'done';
            connectSource(sh);
        }
    }

    P5Support.DataSource {
        id: opener
        engine: "executable"
        connectedSources: []
        onNewData: (s) => disconnectSource(s)
        function open(path) {
            var cmd = plasmoid.configuration.openCommand.replace(/%d/g, '"' + path + '"');
            connectSource(cmd);
        }
    }

    Timer {
        interval: plasmoid.configuration.pollInterval
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: scanner.scan()
    }
    // rescan promptly when the repo list changes
    Connections {
        target: plasmoid.configuration
        function onReposChanged() { scanner.scan(); }
    }

    function parse(out) {
        var rows = [];
        var lines = out.split("\n");
        for (var i = 0; i < lines.length; i++) {
            var L = lines[i].trim();
            if (L.length === 0) continue;
            var c = L.split("|");
            if (c.length < 6) continue;
            rows.push({
                path: c[0], branch: c[1],
                dirty: parseInt(c[2]) || 0,
                ahead: parseInt(c[3]) || 0,
                behind: parseInt(c[4]) || 0,
                type: c[5], ok: c[1] !== "!"
            });
        }
        repos = rows;
    }

    // ---- compact ----------------------------------------------------------
    compactRepresentation: RowLayout {
        spacing: Lattice.Theme.xs
        Lattice.MonoText { text: String.fromCharCode(0xf126); tone: root.accent; font.pixelSize: Lattice.Theme.fsCaption }
        Lattice.MonoText {
            text: {
                var d = 0;
                for (var i = 0; i < root.repos.length; i++) d += root.repos[i].dirty;
                return d > 0 ? "●" + d : "clean";
            }
            tone: Lattice.Theme.dim; font.pixelSize: Lattice.Theme.fsCaption
        }
        MouseArea { anchors.fill: parent; onClicked: root.expanded = !root.expanded }
    }

    // ---- full -------------------------------------------------------------
    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        implicitWidth: Kirigami.Units.gridUnit * 18
        implicitHeight: col.implicitHeight + Lattice.Theme.md * 2

        Lattice.Scrim { anchors.fill: parent; strength: root.scrim }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: Lattice.Theme.md
            spacing: Lattice.Theme.xs

            RowLayout {
                Layout.fillWidth: true
                Lattice.Caption { text: "stack" }
                Item { Layout.fillWidth: true }
                Lattice.MonoText {
                    text: root.repos.length + (root.repos.length === 1 ? " repo" : " repos")
                    tone: Lattice.Theme.faint; font.pixelSize: Lattice.Theme.fsMicro
                }
            }
            Lattice.Hairline { Layout.fillWidth: true; Layout.bottomMargin: Lattice.Theme.xs }

            // empty state
            Lattice.MonoText {
                visible: root.repos.length === 0
                Layout.fillWidth: true
                Layout.topMargin: Lattice.Theme.sm
                text: "no repositories — add paths in settings"
                tone: Lattice.Theme.faint
                font.pixelSize: Lattice.Theme.fsCaption
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: root.repos
                delegate: Item {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: rowL.implicitHeight + Lattice.Theme.xs * 2

                    Rectangle {   // hover wash
                        anchors.fill: parent
                        color: hov.hovered ? Lattice.Theme.fg(0.05) : "transparent"
                        radius: Lattice.Theme.xs
                    }
                    HoverHandler { id: hov }
                    TapHandler {
                        enabled: modelData.ok
                        onTapped: opener.open(modelData.path)
                    }

                    RowLayout {
                        id: rowL
                        anchors.fill: parent
                        anchors.leftMargin: Lattice.Theme.xs
                        anchors.rightMargin: Lattice.Theme.xs
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Lattice.Theme.sm

                        // type tag
                        Rectangle {
                            Layout.preferredWidth: tag.implicitWidth + Lattice.Theme.sm
                            Layout.preferredHeight: tag.implicitHeight + Lattice.Theme.xs
                            color: "transparent"
                            border.width: Lattice.Theme.hair
                            border.color: modelData.ok ? Lattice.Theme.alpha(root.accent, 0.5) : Lattice.Theme.ghost
                            radius: Lattice.Theme.xs
                            Lattice.MonoText {
                                id: tag
                                anchors.centerIn: parent
                                text: modelData.type === "NONE" ? "—" : modelData.type
                                tone: modelData.ok ? root.accent : Lattice.Theme.faint
                                font.pixelSize: Lattice.Theme.fsMicro
                            }
                        }

                        Lattice.MonoText {
                            Layout.fillWidth: true
                            text: root.baseName(modelData.path)
                            tone: modelData.ok ? Lattice.Theme.ink : Lattice.Theme.faint
                            font.pixelSize: Lattice.Theme.fsCaption
                        }

                        Lattice.MonoText {
                            visible: modelData.ok
                            text: modelData.branch
                            tone: Lattice.Theme.dim
                            font.pixelSize: Lattice.Theme.fsMicro
                            Layout.maximumWidth: Kirigami.Units.gridUnit * 5
                        }

                        // ahead / behind
                        Lattice.MonoText {
                            visible: modelData.ok && modelData.ahead > 0
                            text: "↑" + modelData.ahead
                            tone: root.accent; font.pixelSize: Lattice.Theme.fsMicro
                        }
                        Lattice.MonoText {
                            visible: modelData.ok && modelData.behind > 0
                            text: "↓" + modelData.behind
                            tone: Lattice.Theme.warn; font.pixelSize: Lattice.Theme.fsMicro
                        }

                        // dirty / clean
                        Lattice.MonoText {
                            visible: modelData.ok
                            text: modelData.dirty > 0 ? "●" + modelData.dirty : "clean"
                            tone: modelData.dirty > 0 ? Lattice.Theme.warn : Lattice.Theme.faint
                            font.pixelSize: Lattice.Theme.fsMicro
                        }
                        Lattice.MonoText {
                            visible: !modelData.ok
                            text: "not a repo"
                            tone: Lattice.Theme.hot; font.pixelSize: Lattice.Theme.fsMicro
                        }
                    }
                }
            }
        }
    }
}
