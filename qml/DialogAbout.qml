import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: dialog
    title: qsTr("About QtOllamaFrontend")
    standardButtons: Dialog.Ok
    modal: true
    closePolicy: Popup.CloseOnEscape
    x: (appWindow.width - width) / 2
    y: (appWindow.height - height) / 2
    width: 500
    height: 300
    clip: true
    ColumnLayout {
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 10
            Image {
                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                Layout.rightMargin: 30
                fillMode: Image.PreserveAspectFit
                source: "qrc:/images/earth.svg"
                sourceSize.width: dialog.width * 0.2
                antialiasing: true
            }
            GridLayout {
                columns: 2
                Layout.fillWidth: true
                // website
                Label {
                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: 10
                    text: "Github"
                }
                Label {
                    antialiasing: true
                    text: "<a href=\"https://github.com/bkweb/ModxLinguist\">https://github.com/bkweb/ModxLinguist</a>"
                    onLinkActivated: function(link) {
                        Qt.openUrlExternally(link);
                    }
                }
                // author
                Label {
                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: 10
                    text: qsTr("Author")
                }
                Label {
                    text: "Björn Kaiser"
                }
                // version
                Label {
                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: 10
                    text: qsTr("Version")
                }
                Label {
                    text: "1.0"
                }
            }
        }
        // disclaimer
        Label {
            Layout.fillWidth: true
            Layout.margins: 20
            wrapMode: Text.WordWrap
            color: Qt.gray
            text: qsTr("This project is a privately developed tool and not officially published by Ollama.")
        }
    }
}
