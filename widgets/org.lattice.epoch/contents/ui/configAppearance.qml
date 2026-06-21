import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls

KCM.SimpleKCM {
    id: page

    property alias cfg_use24h: h24.checked
    property alias cfg_showSeconds: secs.checked
    property alias cfg_showEpoch: epoch.checked
    property alias cfg_showUptime: uptime.checked
    property string cfg_accentColor: ""
    property alias cfg_scrimStrength: scrimSlider.value

    Kirigami.FormLayout {
        QQC.CheckBox { id: h24; Kirigami.FormData.label: i18n("Clock:"); text: i18n("24-hour") }
        QQC.CheckBox { id: secs; text: i18n("Show seconds") }

        Item { Kirigami.FormData.isSection: true }

        QQC.CheckBox { id: epoch; Kirigami.FormData.label: i18n("Readouts:"); text: i18n("Unix epoch counter") }
        QQC.CheckBox { id: uptime; text: i18n("Uptime") }

        Item { Kirigami.FormData.isSection: true }

        QQC.CheckBox {
            id: followTheme
            Kirigami.FormData.label: i18n("Accent:")
            text: i18n("Follow desktop highlight")
            checked: page.cfg_accentColor === ""
            onToggled: page.cfg_accentColor = checked ? "" : Kirigami.Theme.highlightColor
        }
        RowLayout {
            visible: !followTheme.checked
            KQuickControls.ColorButton {
                showAlphaChannel: false
                color: page.cfg_accentColor !== "" ? page.cfg_accentColor : Kirigami.Theme.highlightColor
                onColorChanged: if (!followTheme.checked) page.cfg_accentColor = color.toString()
            }
            QQC.Label { text: page.cfg_accentColor }
        }

        Item { Kirigami.FormData.isSection: true }

        RowLayout {
            Kirigami.FormData.label: i18n("Backing scrim:")
            QQC.Slider {
                id: scrimSlider
                from: 0; to: 1; stepSize: 0.05
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            }
            QQC.Label { text: Math.round(scrimSlider.value * 100) + "%" }
        }
    }
}
