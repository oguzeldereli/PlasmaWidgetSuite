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

    TaskManager.TasksModel {
        id: tasksModel
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortDisabled
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
        implicitWidth: root.vertical ? vbar.implicitWidth + Lattice.Theme.sm * 2
                                     : Math.max(Kirigami.Units.gridUnit * 2, bar.implicitWidth + Lattice.Theme.sm)
        implicitHeight: root.vertical ? Math.max(Kirigami.Units.gridUnit * 2, vbar.implicitHeight + Lattice.Theme.sm)
                                      : bar.implicitHeight + Lattice.Theme.sm
        Layout.minimumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight

        Lattice.Scrim { anchors.fill: parent; strength: root.scrim }

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
            anchors.centerIn: parent
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
