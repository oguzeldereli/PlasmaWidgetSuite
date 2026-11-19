import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import "lattice" as Lattice

PlasmoidItem {
    id: root

    readonly property color accent: plasmoid.configuration.accentColor.length > 0
        ? plasmoid.configuration.accentColor : Lattice.Theme.accentDefault
    readonly property real scrim: plasmoid.configuration.scrimStrength
    readonly property real iconPx: Lattice.Theme.lg * plasmoid.configuration.iconScale
    readonly property bool vertical: plasmoid.formFactor === PlasmaCore.Types.Vertical

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    property bool _restoring: false
    property bool dragging: false     // a cell is being dragged along the tape

    TaskManager.TasksModel {
        id: tasksModel
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortManual   // user order, via drag
        filterByVirtualDesktop: plasmoid.configuration.onlyCurrentDesktop
        filterByScreen: false
        filterByActivity: false
        launchInPlace: true          // a pinned app and its window share one slot
        separateLaunchers: false
        onLauncherListChanged: root.saveLaunchers()
    }

    Component.onCompleted: restoreLaunchers()

    function restoreLaunchers() {
        _restoring = true;
        var s = plasmoid.configuration.launchers.trim();
        tasksModel.launcherList = s.length > 0 ? s.split("\n") : [];
        _restoring = false;
    }
    function saveLaunchers() {
        if (_restoring) return;
        plasmoid.configuration.launchers = tasksModel.launcherList.join("\n");
    }
    function togglePin(hasLauncher, url) {
        if (hasLauncher) tasksModel.requestRemoveLauncher(url);
        else tasksModel.requestAddLauncher(url);
    }

    // Drag-to-reorder. `cell` is the dragged DeckCell, (mx, my) the pointer in
    // its coordinates. Only swap once the pointer is far enough into the target
    // that, after the move, it sits inside the dragged cell again — otherwise
    // cells of unequal width would swap back and forth under a still pointer.
    function dragOver(cell, mx, my) {
        var bar = cell.parent;
        if (!bar) return;
        var p = cell.mapToItem(bar, mx, my);
        var t = bar.childAt(p.x, p.y);
        if (!t || t === cell || t.itemIndex === undefined || t.itemIndex < 0) return;
        var from = cell.itemIndex, to = t.itemIndex;
        var pos   = root.vertical ? p.y : p.x;
        var tPos  = root.vertical ? t.y : t.x;
        var tSize = root.vertical ? t.height : t.width;
        var dSize = root.vertical ? cell.height : cell.width;
        if (to > from && pos < tPos + tSize - dSize) return;
        if (to < from && pos > tPos + dSize) return;
        tasksModel.move(from, to);
    }
    function endDrag() {
        dragging = false;
        tasksModel.syncLaunchers();   // persist pinned order (-> launcherList -> config)
    }

    function activate(i) {
        var idx = tasksModel.makeModelIndex(i);
        tasksModel.requestActivate(idx);
    }
    function toggleMin(i) {
        tasksModel.requestToggleMinimized(tasksModel.makeModelIndex(i));
    }
    function close(i) {
        tasksModel.requestClose(tasksModel.makeModelIndex(i));
    }

    Component {
        id: cellDelegate
        DeckCell {
            id: dc
            iconSource: model.decoration
            title: model.display ? model.display : (model.AppName ? model.AppName : "")
            active: model.IsActive === true
            minimized: model.IsMinimized === true
            attention: model.IsDemandingAttention === true
            isLauncher: model.IsLauncher === true
            pinned: model.HasLauncher === true
            mono: plasmoid.configuration.monoIcons
            alwaysLabel: plasmoid.configuration.alwaysLabels
            iconPx: root.iconPx
            accent: root.accent
            first: index === 0
            itemIndex: index
            onDragStarted: root.dragging = true
            onDragMoved: (mx, my) => root.dragOver(dc, mx, my)
            onDragEnded: root.endDrag()
            onLeftClicked: (!model.IsLauncher && model.IsActive) ? root.toggleMin(index) : root.activate(index)
            onMiddleClicked: if (model.IsClosable) root.close(index)
            onRightClicked: ctxMenu.popup()

            QQC.Menu {
                id: ctxMenu
                QQC.MenuItem {
                    text: model.HasLauncher ? i18n("Unpin from deck") : i18n("Pin to deck")
                    onTriggered: root.togglePin(model.HasLauncher, model.LauncherUrlWithoutIcon)
                }
                QQC.MenuItem {
                    text: model.IsMinimized ? i18n("Restore") : i18n("Minimize")
                    visible: !model.IsLauncher
                    height: visible ? implicitHeight : 0
                    onTriggered: root.toggleMin(index)
                }
                QQC.MenuSeparator { visible: !model.IsLauncher; height: visible ? implicitHeight : 0 }
                QQC.MenuItem {
                    text: i18n("Close")
                    visible: !model.IsLauncher
                    height: visible ? implicitHeight : 0
                    enabled: model.IsClosable
                    onTriggered: root.close(index)
                }
            }
        }
    }

    fullRepresentation: Item {
        id: full

        // ── Hover-stable geometry (horizontal) ────────────────────────────
        // Hovering a cell slides its label open. If that widened the applet,
        // the panel spacers would re-centre the whole tape under the pointer,
        // which can push the pointer onto a neighbour (→ collapse → jitter).
        // So: size the applet from the *resting* tape plus room for one hover
        // label, keep the resting tape centred, let hover grow only rightward,
        // and freeze all of it while the pointer is on the deck or dragging.
        function sumCells(prop, useMax) {
            var acc = 0, c = bar.children;
            for (var i = 0; i < c.length; i++) {
                var v = c[i][prop];
                if (v === undefined) continue;
                acc = useMax ? Math.max(acc, v) : acc + v;
            }
            return acc;
        }
        readonly property real restWidth: sumCells("restWidth", false)
        readonly property real hoverReserve: sumCells("hoverGrow", true)
        readonly property real liveW: Math.max(Kirigami.Units.gridUnit * 2,
                                               restWidth + hoverReserve * 2 + Lattice.Theme.sm)
        readonly property real liveX: (liveW - restWidth) / 2
        readonly property bool hold: deckHover.hovered || root.dragging
        property real heldW: 0
        property real heldX: 0
        function sync() { if (!hold) { heldW = liveW; heldX = liveX; } }
        onLiveWChanged: sync()
        onLiveXChanged: sync()
        onHoldChanged: sync()
        Component.onCompleted: { heldW = liveW; heldX = liveX; }

        HoverHandler { id: deckHover }

        implicitWidth: root.vertical ? vbar.implicitWidth + Lattice.Theme.sm * 2 : heldW
        implicitHeight: root.vertical ? Math.max(Kirigami.Units.gridUnit * 2, vbar.implicitHeight + Lattice.Theme.sm)
                                      : bar.implicitHeight + Lattice.Theme.sm
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Layout.maximumWidth: root.vertical ? -1 : implicitWidth
        Layout.minimumHeight: implicitHeight

        Lattice.Scrim {
            anchors.fill: root.vertical ? vbar : bar
            anchors.margins: -Lattice.Theme.sm / 2
            visible: tasksModel.count > 0
            strength: root.scrim
        }

        Lattice.Caption {
            anchors.centerIn: parent
            visible: tasksModel.count === 0
            text: "no windows"
            tone: Lattice.Theme.faint
            font.pixelSize: Lattice.Theme.fsMicro
        }

        Row {
            id: bar
            visible: !root.vertical
            x: full.heldX
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Repeater { model: tasksModel; delegate: cellDelegate }
        }
        Column {
            id: vbar
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 0
            Repeater { model: tasksModel; delegate: cellDelegate }
        }
    }
}
