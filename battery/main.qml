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

        Rectangle {
            anchors.fill: parent
            color: "black"

            Row {
                anchors.fill: parent

                Rectangle {
                    width: parent.width / 2
                    height: parent.height
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
                    height: parent.height
                    color: "transparent"

                    Column {
                        anchors.centerIn: parent
                        // width: parent.width
                        // height: parent.height
                        spacing: 6
                        Text {
                            id: percent
                            text: Battery.percentage + "%"
                            color: "white"
                            font.pixelSize: 50
                            font.weight: Font.Black
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            id: message
                            text: ""
                            color: "white"
                            font.pixelSize: 20
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                }
            }
        }

        Button {
            id: dismissBtn
            visible: popup.persistent
            text: "Dismiss"
            onClicked: {
                popup.visible = false;
                popup.persistent = false;
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
            popup.showNotification("Battey Low", "electricx.svg", true);
        }

        function onFullBattery() {
            popup.showNotification("Full", "electric.svg");
        }

        function onAcChanged() {
            if (Battery.acConnected) {
                popup.showNotification("Charging", "electric.svg");
            } else {
                popup.showNotification("Discharging", "electricx.svg");
            }
        }
    }
}
