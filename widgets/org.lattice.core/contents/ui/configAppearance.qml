import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls

KCM.SimpleKCM {
    id: page

    property alias cfg_pollInterval: pollSpin.value
    property alias cfg_gpuIndex: gpuSpin.value
    property alias cfg_showGpu: gpuCheck.checked
    property alias cfg_showCpu: cpuCheck.checked
    property alias cfg_showRam: ramCheck.checked
    property string cfg_accentColor: ""
    property alias cfg_scrimStrength: scrimSlider.value

    Kirigami.FormLayout {
        QQC.SpinBox {
            id: pollSpin
            Kirigami.FormData.label: i18n("Update interval (ms):")
            from: 500; to: 10000; stepSize: 250
        }
        QQC.SpinBox {
            id: gpuSpin
            Kirigami.FormData.label: i18n("GPU index:")
            from: 0; to: 7
        }

        Item { Kirigami.FormData.isSection: true }

        QQC.CheckBox { id: gpuCheck; Kirigami.FormData.label: i18n("Show:"); text: i18n("GPU + VRAM") }
        QQC.CheckBox { id: cpuCheck; text: i18n("CPU") }
        QQC.CheckBox { id: ramCheck; text: i18n("Memory") }

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
                id: colorBtn
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
