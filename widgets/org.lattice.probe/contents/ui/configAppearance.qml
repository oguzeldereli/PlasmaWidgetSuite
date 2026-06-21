import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls

KCM.SimpleKCM {
    id: page

    property alias cfg_pollInterval: pollSpin.value
    property string cfg_accentColor: ""
    property alias cfg_scrimStrength: scrimSlider.value

    Kirigami.FormLayout {
        QQC.SpinBox {
            id: pollSpin
            Kirigami.FormData.label: i18n("Update interval (ms):")
            from: 500; to: 5000; stepSize: 250
        }

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
