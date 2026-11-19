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
    readonly property real glyphPx: Lattice.Theme.fsReadout * plasmoid.configuration.glyphScale
    readonly property bool vertical: plasmoid.formFactor === PlasmaCore.Types.Vertical

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation   // render inline in panels too

    // built-in dev set (FA Nerd Font glyphs), used when config is empty
    readonly property var defaults: [
        { glyph: String.fromCharCode(0xf120), label: "Terminal", cmd: "konsole" },
        { glyph: String.fromCharCode(0xf121), label: "Code",     cmd: "code" },
        { glyph: String.fromCharCode(0xf268), label: "Chrome",   cmd: "google-chrome-stable" },
        { glyph: String.fromCharCode(0xf07c), label: "Files",    cmd: "dolphin" },
        { glyph: String.fromCharCode(0xf1bc), label: "Spotify",  cmd: "flatpak run com.spotify.Client" },
        { glyph: String.fromCharCode(0xf002), label: "Run",      cmd: "krunner" }
    ]

    readonly property var model: {
        var raw = plasmoid.configuration.launchers.trim();
        if (raw.length === 0) return defaults;
        var out = [];
        var lines = raw.split("\n");
        for (var i = 0; i < lines.length; i++) {
            var L = lines[i].trim();
            if (L.length === 0) continue;
            var p = L.split("|");
            if (p.length < 3) continue;
            out.push({ glyph: p[0].trim(), label: p[1].trim(), cmd: p.slice(2).join("|").trim() });
        }
        return out.length > 0 ? out : defaults;
    }

    P5Support.DataSource {
        id: launcher
        engine: "executable"
        connectedSources: []
        onNewData: (s) => disconnectSource(s)
        function run(cmd) { if (cmd && cmd.length) connectSource("kstart " + cmd); }
    }

    fullRepresentation: Item {
        implicitWidth: root.vertical ? vbar.implicitWidth + Lattice.Theme.sm * 2 : bar.implicitWidth + Lattice.Theme.md
        implicitHeight: root.vertical ? vbar.implicitHeight + Lattice.Theme.md : bar.implicitHeight + Lattice.Theme.sm
        Layout.minimumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight

        Lattice.Scrim { anchors.fill: parent; strength: root.scrim }

        // ---- horizontal ----
        Row {
            id: bar
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: 0

            Row {   // prompt
                visible: plasmoid.configuration.showPrompt
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: Lattice.Theme.sm
                rightPadding: Lattice.Theme.xs
                Lattice.Caption {
                    text: "›"
                    tone: root.accent
                    font.pixelSize: root.glyphPx * 0.8
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {   // blinking caret
                    id: caret
                    width: Math.max(2, Lattice.Theme.hair * 2)
                    height: root.glyphPx * 0.9
                    color: root.accent
                    anchors.verticalCenter: parent.verticalCenter
                    // Hard terminal-style blink: 2 redraws/s. A tweened infinite
                    // animation would repaint the whole panel every vsync.
                    Timer {
                        interval: 600; running: true; repeat: true
                        onTriggered: caret.opacity = caret.opacity > 0.5 ? 0 : 1
                    }
                }
            }

            Repeater {
                model: root.model
                delegate: RailCell {
                    required property var modelData
                    required property int index
                    glyph: modelData.glyph
                    label: modelData.label
                    glyphPx: root.glyphPx
                    accent: root.accent
                    alwaysLabel: plasmoid.configuration.alwaysLabels
                    first: index === 0 && !plasmoid.configuration.showPrompt
                    onActivated: launcher.run(modelData.cmd)
                }
            }
        }

        // ---- vertical ----
        Column {
            id: vbar
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 0
            Repeater {
                model: root.model
                delegate: RailCell {
                    required property var modelData
                    required property int index
                    glyph: modelData.glyph
                    label: modelData.label
                    glyphPx: root.glyphPx
                    accent: root.accent
                    alwaysLabel: plasmoid.configuration.alwaysLabels
                    first: index === 0
                    onActivated: launcher.run(modelData.cmd)
                }
            }
        }
    }
}
