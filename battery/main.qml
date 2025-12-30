import QtQuick
import QtQuick.Window
import QtQuick.Controls

ApplicationWindow {
    id: popup
    visible: false
    width: 400
    height: 200
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"
    title: "Battery Notification"
    property bool persistent: false

    Rectangle {
        anchors.fill: parent
        anchors.margins: 10
        color: "black"

        Column {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 10

            Rectangle {
                anchors.fill: parent
                color: "black"

                Row {
                    anchors.fill: parent

                    Rectangle {
                        width: parent.width / 2
                        height: width - 50
                        color: "transparent"

                        Image {
                            id: logo
                            anchors.margins: 30
                            anchors.fill: parent
                            // width: parent.width / 2
                            // height: width-50
                            source: "" // Will be set dynamically
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    Rectangle {

                        width: parent.width / 2
                        height: parent.height - dismissBtn.height
                        color: "transparent"
                        Text {
                            id: message
                            anchors.centerIn: parent
                            text: ""
                            color: "white"
                            font.pixelSize: 50
                            wrapMode: Text.Wrap
                            // width: parent.width - logo.width - 10  // Subtract spacing
                        }
                    }
                }
            }

            Button {
                id: dismissBtn
                // visible: popup.persistent
                text: "Dismiss"
                onClicked: {
                    popup.visible = false;
                    popup.persistent = false;
                }
            }
        }
    }

    Timer {
        id: autoHideTimer
        interval: 4000
        running: false
        repeat: false
        onTriggered: {
            if (!popup.persistent) {
                popup.visible = false;
            }
        }
    }

    function showNotification(text, imageSource = "", persistent = false) {
        message.text = text;
        logo.source = imageSource;  // Set the image dynamically
        popup.persistent = persistent;
        dismissBtn.visible = persistent;
        popup.visible = true;
        if (!persistent) {
            autoHideTimer.restart();
        }
    }

    Connections {
        target: Battery

        function onLowBattery() {
            popup.showNotification(Battery.percentage + "%", "electricx.svg", true);
        }

        function onFullBattery() {
            popup.showNotification("Full", "electric.svg");
        }

        function onAcChanged() {
            if (Battery.acConnected) {
                popup.showNotification(Battery.percentage + "%", "electric.svg");
            } else {
                popup.showNotification(Battery.percentage + "%", "electricx.svg");
            }
        }
    }
}
