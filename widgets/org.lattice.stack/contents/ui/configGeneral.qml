import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_repos: reposArea.text
    property alias cfg_pollInterval: pollSpin.value
    property alias cfg_openCommand: openField.text

    Kirigami.FormLayout {
        QQC.Label {
            Kirigami.FormData.label: i18n("Repositories:")
            text: i18n("One absolute path per line. ~ is expanded.")
            opacity: 0.7
        }
        QQC.ScrollView {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 22
            Layout.preferredHeight: Kirigami.Units.gridUnit * 9
            QQC.TextArea {
                id: reposArea
                wrapMode: TextEdit.NoWrap
                placeholderText: "~/Projects/PlasmaWidgetSuite\n~/Projects/ml-pipeline\n~/work/api"
                font.family: "monospace"
            }
        }

        Item { Kirigami.FormData.isSection: true }

        QQC.TextField {
            id: openField
            Kirigami.FormData.label: i18n("Open command:")
            Layout.preferredWidth: Kirigami.Units.gridUnit * 22
            placeholderText: "code \"%d\""
        }
        QQC.Label {
            text: i18n("Runs when a repo is clicked. %d = repo path.")
            opacity: 0.7
        }

        Item { Kirigami.FormData.isSection: true }

        QQC.SpinBox {
            id: pollSpin
            Kirigami.FormData.label: i18n("Refresh interval (ms):")
            from: 2000; to: 60000; stepSize: 1000
        }
    }
}
