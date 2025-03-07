import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtTextToSpeech
import QtOllamaFrontend.QtOllamaFrontend 1.0

ApplicationWindow {
    id: appWindow
    width: 800
    height: 700
    visible: true
    title: qsTr("QtOllamaFrontend")

    function roundNumber(number) {
        return (Math.round(parseFloat(number) * 100.0) / 100.0).toFixed(2);
    }
    function getPrettyPrintedSize(size) {
        var output = "";

        if (size >= 1024*1024*1024*1024) {
            var size_tb = parseFloat(size) / parseFloat(1024*1024*1024*1024);
            output = roundNumber(size_tb) + " TB";
        } else if (size >= 1024*1024*1024) {
            var size_gb = parseFloat(size) / parseFloat(1024*1024*1024);
            output = roundNumber(size_gb) + " GB";
        } else if (size >= 1024*1024) {
            var size_mb = parseFloat(size) / parseFloat(1024*1024);
            output = roundNumber(size_mb) + " MB";
        } else if (size >= 1024) {
            var size_kb = parseFloat(size) / parseFloat(1024);
            output = roundNumber(size_kb) + " kB";
        } else {
            var size_b = parseFloat(size);
            output = roundNumber(size_b)  + " B";
        }

        return output;
    }

    TextToSpeech {
        id: textToSpeech
        Component.onCompleted: {
            if (qtOllamaFrontend.ttsEngine != "") {
                var engines = availableEngines();
                var index = engines.indexOf(qtOllamaFrontend.ttsEngine);

                if (index >= 0) {
                    console.log("selected engine:", availableEngines()[index]);
                    engine = availableEngines()[index];
                }
            }

            if (qtOllamaFrontend.ttsLocale != "") {
                var locales = availableLocales().map((locale) => locale.nativeLanguageName);
                var index = locales.indexOf(qtOllamaFrontend.ttsLocale);

                if (index >= 0) {
                    console.log("selected locale:", availableLocales()[index].nativeLanguageName);
                    locale = availableLocales()[index];
                }
            }

            if (qtOllamaFrontend.ttsVoice != "") {
                var voices = availableVoices().map((voice) => voice.name);
                var index = voices.indexOf(qtOllamaFrontend.ttsVoice);

                if (index >= 0) {
                    console.log("selected voice:", availableVoices()[index].name);
                    voice = availableVoices()[index];
                }
            }

            rate = qtOllamaFrontend.ttsRate;
            pitch = qtOllamaFrontend.ttsPitch;
            volume = qtOllamaFrontend.ttsVolume;
        }
    }

    Connections {
        target: qtOllamaFrontend
        ignoreUnknownSignals: true
        function onSay(text) {
            if (qtOllamaFrontend.outputTts) {
                textToSpeech.say(text);
            }
        }
        function onReceivedResponse(result) {
            const json = JSON.parse(result);

            if (json.message) {
                listViewMessages.addMessage({
                    "role": json.message.role,
                    "content": json.message.content,
                    "imageUrl": "",
                    "done": json.message.done
                });
            }

            if (checkBoxTextMessageMultiline.checked) {
                textArea.forceActiveFocus();
            } else {
                textField.forceActiveFocus();
            }
        }
        function onReceivedNewChatStarted() {
            listModelMessages.clear();

            listViewLog.addText({
                "title": qsTr("new chat started"),
                "data": ""
            });
        }
        function onLog(title, data) {
            var json = {};

            try {
                json = JSON.parse(data);
            } catch (e) {
                json = {
                    "data": data
                }
            }

            listViewLog.addText({
                "title": title,
                "data": JSON.stringify(json, null, 4)
            });
        }
        function onReceivedNetworkError(result) {
            console.log("network error:", result);
            listViewLog.addText({
                "title": "",
                "data": qsTr("network error: %1").arg(result)
            });
        }
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Vertical
        SplitView {
            SplitView.fillHeight: true
            orientation: Qt.Horizontal
            ScrollView {
                SplitView.fillWidth: true
                ScrollBar.horizontal.visible: false
                smooth: true
                ListView {
                    id: listViewMessages
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    CustomButton {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        text: qsTr("Clear Chat")
                        onClicked: {
                            listModelMessages.clear();
                        }
                    }
                    function addMessage(message) {
                        if (message.done) {
                            // add new message list item
                            listModelMessages.append({
                                "role": message.role,
                                "content": message.content,
                                "imageUrl": message.imageUrl != "" ? message.imageUrl : "",
                                "done": message.done
                            });
                        } else {
                            // stream
                            var index = listModelMessages.count - 1;
                            var lastMessage = listModelMessages.get(index);

                            if (lastMessage.done) {
                                // add new message list item
                                listModelMessages.append({
                                    "role": message.role,
                                    "content": message.content,
                                    "imageUrl": message.imageUrl != "" ? message.imageUrl : "",
                                    "done": message.done
                                });
                            } else {
                                // update last message list item
                                listModelMessages.set(index, {
                                    "content": message.content,
                                    "done": message.done
                                });
                            }
                        }

                        listViewMessages.positionViewAtEnd();
                    }
                    model: ListModel {
                        id: listModelMessages
                    }
                    delegate: ItemDelegate {
                        id: item
                        property bool done: model.done
                        width: listViewMessages.width
                        height: itemDelegateRow.height
                        background: Rectangle {
                            color: "#eeeeee"
                        }
                        onClicked: {
                            textToSpeech.say(model.content);
                        }
                        RowLayout {
                            id: itemDelegateRow
                            width: parent.width
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.margins: 10
                                RowLayout {
                                    Layout.fillWidth: true
                                    CustomLabel {
                                        color: model.role == "user" ? "#77dd77" : "#77dddd"
                                        text: model.role == "user" ? qsTr("You") : qsTr("Assistant")
                                    }
                                    CustomButton {
                                        text: qsTr("Play")
                                        onClicked: {
                                            textToSpeech.say(model.content);
                                        }
                                    }
                                    CustomButton {
                                        text: qsTr("Copy To Clipboard")
                                        onClicked: {
                                            qtOllamaFrontend.copyTextToClipboard(model.content);
                                        }
                                    }
                                }
                                CustomTextArea {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    readOnly: true
                                    wrapMode: Text.WordWrap
                                    text: model.content
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            textToSpeech.say(model.content);
                                        }
                                    }
                                }
                                Image {
                                    Layout.leftMargin: 10
                                    Layout.preferredWidth: 100
                                    Layout.preferredHeight: 100
                                    fillMode: Image.PreserveAspectFit
                                    antialiasing: true
                                    smooth: true
                                    sourceSize.width: 100
                                    sourceSize.height: 100
                                    visible: model.imageUrl != ""
                                    source: model.imageUrl
                                }
                            }
                        }
                    }
                }
            }
            ScrollView {
                id: scrollViewLog
                SplitView.preferredWidth: 0.5 * appWindow.width
                SplitView.minimumWidth: 0.1 * appWindow.width
                SplitView.maximumWidth: 0.9 * appWindow.width
                ScrollBar.horizontal.visible: false
                smooth: true
                visible: actionShowLog.checked
                ListView {
                    id: listViewLog
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    CustomButton {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        text: qsTr("Clear Log")
                        onClicked: {
                            listModelLog.clear();
                        }
                    }
                    function addText(entry) {
                        listModelLog.append({
                            "title": entry.title,
                            "data": entry.data
                        });

                        listViewLog.positionViewAtEnd();
                    }
                    model: ListModel {
                        id: listModelLog
                    }
                    delegate: ItemDelegate {
                        id: itemLog
                        width: listViewLog.width
                        height: itemDelegateRowLog.height
                        background: Rectangle {
                            color: "#eeeeee"
                        }
                        RowLayout {
                            id: itemDelegateRowLog
                            width: parent.width
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.margins: 10
                                CustomLabel {
                                    text: model.title
                                    color: "#111188"
                                    visible: model.title != ""
                                }
                                CustomTextArea {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    readOnly: true
                                    wrapMode: Text.WordWrap
                                    text: model.data
                                    visible: model.data != ""
                                }
                            }
                        }
                    }
                }
            }
        }
        RowLayout {
            SplitView.preferredHeight: implicitHeight
            SplitView.minimumHeight: implicitHeight
            SplitView.maximumHeight: 0.25 * appWindow.height
            // message text - single line
            CustomTextField {
                id: textField
                Layout.fillWidth: true
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                font.pointSize: 12
                placeholderText: qsTr("Message Text")
                visible: !checkBoxTextMessageMultiline.checked
                onTextChanged: textArea.text = text
                onAccepted: {
                    const messageContent = textField.text.trim();

                    if (messageContent == "") {
                        if (checkBoxTextMessageMultiline.checked) {
                            textArea.forceActiveFocus();
                        } else {
                            textField.forceActiveFocus();
                        }
                        return;
                    }

                    textField.text = "";

                    listViewMessages.addMessage({
                        "role": "user",
                        "content": messageContent,
                        "imageUrl": "",
                        "done": true
                    });

                    qtOllamaFrontend.sendMessage(messageContent, "");
                }
            }
            // message text - multiline
            ColumnLayout {
                Layout.fillWidth: true
                visible: checkBoxTextMessageMultiline.checked
                CustomTextArea {
                    id: textArea
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    font.pointSize: 12
                    placeholderText: qsTr("Message Text")
                    onTextChanged: textField.text = text
                }
                CustomButton {
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    text: qsTr("Send Message")
                    onClicked: {
                        const messageContent = textArea.text.trim();

                        if (messageContent == "") {
                            if (checkBoxTextMessageMultiline.checked) {
                                textArea.forceActiveFocus();
                            } else {
                                textField.forceActiveFocus();
                            }
                            return;
                        }

                        textArea.text = "";

                        listViewMessages.addMessage({
                            "role": "user",
                            "content": messageContent,
                            "imageUrl": "",
                            "done": true
                        });

                        qtOllamaFrontend.sendMessage(messageContent, "");
                    }
                }
            }
        }
    }

    menuBar: MenuBar {
        Menu {
            title: qsTr("&Chat")
            DialogNewChat {
                id: dialogNewChat
                onAccepted: qtOllamaFrontend.startNewChat()
            }
            Action {
                id: actionNewChat
                shortcut: "Ctrl+N"
                text: qsTr("&New Chat")
                onTriggered: dialogNewChat.open()
            }
            MenuSeparator { }
            DialogImage {
                id: dialogImage
                onAccepted: {
                    var jsonImages = images.length > 0 ? JSON.parse(images) : "";

                    listViewMessages.addMessage({
                        "role": "user",
                        "content": messageText,
                        "imageUrl": images.length > 0 ? jsonImages[0] : "",
                        "done": true
                    });

                    qtOllamaFrontend.sendMessage(messageText, images);
                }
            }
            Action {
                id: actionImage
                text: qsTr("&Message with Image")
                onTriggered: dialogImage.open()
            }
            DialogExportMessages {
                id: dialogExportMessages
            }
            Action {
                shortcut: "Ctrl+S"
                text: qsTr("&Export Chat Messages")
                onTriggered: dialogExportMessages.open()
            }
            MenuSeparator { }
            Action {
                id: actionTextMessageMultiline
                text: qsTr("&Multiline Text Field")
                checkable: true
                checked: checkBoxTextMessageMultiline.checked
                onTriggered: {
                    checkBoxTextMessageMultiline.click();
                }
            }
            MenuSeparator { }
            Action {
                text: qsTr("&Quit")
                onTriggered: appWindow.close()
            }
        }
        Menu {
            title: qsTr("&Model")
            DialogSelectModel {
                id: dialogSelectModel
            }
            Action {
                shortcut: "Ctrl+M"
                text: qsTr("&Select Model")
                onTriggered: dialogSelectModel.open()
            }
            DialogPullModel {
                id: dialogPullModel
            }
            Action {
                text: qsTr("&Pull Model")
                onTriggered: dialogPullModel.open()
            }
            DialogAddModel {
                id: dialogAddModel
                onAccepted: {
                    qtOllamaFrontend.addModelToDb(modelName, modelDescription, modelParameterSize, modelSize);
                }
            }
            Action {
                text: qsTr("&Add Model")
                onTriggered: dialogAddModel.open()
            }
            DialogModelOptions {
                id: dialogModelOptions
            }
            Action {
                text: qsTr("Model &Options")
                onTriggered: dialogModelOptions.open()
            }
            MenuSeparator { }
            Action {
                id: actionStream
                text: qsTr("S&tream Responses")
                checkable: true
                checked: checkBoxStream.checked
                onTriggered: {
                    checkBoxStream.checked = checked;
                }
            }
        }
        Menu {
            title: qsTr("&Settings")
            DialogModelSettings {
                id: dialogModelSettings
            }
            Action {
                text: qsTr("&Model")
                onTriggered: dialogModelSettings.open()
            }
            DialogService {
                id: dialogService
            }
            Action {
                text: qsTr("&Service")
                onTriggered: dialogService.open()
            }
            DialogTextToSpeech {
                id: dialogTextToSpeech
                textToSpeech: textToSpeech
            }
            Action {
                shortcut: "Ctrl+T"
                text: qsTr("&Text to Speech")
                onTriggered: dialogTextToSpeech.open()
            }
            MenuSeparator { }
            Action {
                id: actionShowLog
                text: qsTr("Show &Log")
                checkable: true
                checked: true
                onTriggered: {
                    qtOllamaFrontend.showLog = checked;
                }
                Component.onCompleted: {
                    checked = qtOllamaFrontend.showLog;
                }
            }
            Action {
                id: actionOutputTts
                text: qsTr("&Output TTS")
                checkable: true
                checked: true
                onTriggered: {
                    qtOllamaFrontend.outputTts = checked;
                }
                Component.onCompleted: {
                    checked = qtOllamaFrontend.outputTts;
                }
            }
        }
        Menu {
            title: qsTr("&Help")
            DialogAbout {
                id: dialogAbout
            }
            Action {
                text: qsTr("&About")
                onTriggered: dialogAbout.open()
            }
        }
    }

    footer: ToolBar {
        RowLayout {
            anchors.fill: parent
            BusyIndicator {
                id: busyIndicator
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                running: qtOllamaFrontend.loading
            }
            Column {
                CheckBox {
                    id: checkBoxTextMessageMultiline
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    text: qsTr("Multiline")
                    checked: qtOllamaFrontend.textMessageMultiline
                    onClicked: {
                        qtOllamaFrontend.textMessageMultiline = checked;
                    }
                }
                CheckBox {
                    id: checkBoxStream
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    text: qsTr("Stream")
                    checked: qtOllamaFrontend.stream
                    onClicked: {
                        qtOllamaFrontend.stream = checked;
                    }
                }
            }
            CustomButton {
                text: qsTr("New Chat")
                onClicked: {
                    actionNewChat.trigger();
                }
            }
            CustomButton {
                text: qsTr("Image")
                onClicked: {
                    actionImage.trigger();
                }
            }
            CustomButton {
                text: qsTr("Text to Speech")
                onClicked: {
                    dialogTextToSpeech.open();
                }
            }
            CustomButton {
                text: qsTr("Stop Playback")
                onClicked: {
                    // workaround - stop() method causes crash
                    textToSpeech.say(" ");
                }
            }
            Item {
                Layout.fillWidth: true
            }
            CustomButton {
                text: qsTr("Select Model")
                onClicked: {
                    dialogSelectModel.open();
                }
            }
            CustomLabel {
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                text: qtOllamaFrontend.modelName
            }
        }
    }
}
