import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_launchers: area.text
    property alias cfg_alwaysLabels: always.checked
    property alias cfg_showPrompt: prompt.checked

    Kirigami.FormLayout {
        QQC.Label {
            Kirigami.FormData.label: i18n("Launchers:")
            text: i18n("One per line:  glyph | label | command\nLeave empty for the built-in dev set. Glyphs use your Nerd Font.")
            opacity: 0.7
        }
        QQC.ScrollView {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 24
            Layout.preferredHeight: Kirigami.Units.gridUnit * 10
            QQC.TextArea {
                id: area
                wrapMode: TextEdit.NoWrap
                font.family: "monospace"
                placeholderText: " | Terminal | konsole\n | Code | code\n | Chrome | google-chrome-stable"
            }
        }
        QQC.Label {
            text: i18n("Commands launch detached via kstart.")
            opacity: 0.7
        }

        Item { Kirigami.FormData.isSection: true }

        QQC.CheckBox { id: always; Kirigami.FormData.label: i18n("Labels:"); text: i18n("Always show (don't hide until hover)") }
        QQC.CheckBox { id: prompt; text: i18n("Show leading ›_ prompt") }
    }
}
