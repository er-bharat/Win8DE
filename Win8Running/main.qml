import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Windows 1.0

ApplicationWindow {
    visible: false
    width: 200
    height: screen.height
    title: "Window Switcher"
    color: "#cc000000"

    WindowModel {
        id: windowModel
    }

    Rectangle {
        id: closebtn
        width: 4
        height: 4
        anchors.left: parent.left
        anchors.top: parent.top
        z: 10
        color: "transparent"

        MouseArea {
            anchors.fill: parent

            onClicked: WindowController.hide()
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.height
        clip: true

        Column {
            id: column
            width: parent.width
            spacing: 12
            padding: 12

            Repeater {
                model: windowModel

                delegate: Rectangle {
                    id: windowCard

                    width: column.width - column.spacing * 2
                    height: width * 9 / 16   // 16:9 aspect ratio
                    radius: 0

                    color: focused ? "#2d6cdf" : "#2a2a2a"
                    border.width: focused ? 2 : 1
                    border.color: focused ? "#6aa9ff" : "#555"

                    // Window title
                    Text {
                        text: appId
                        color: "white"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        width: parent.width - 48
                    }

                    // Activate window when clicking the card
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        // onEntered: hoverTimer.start()
                        // onExited: hoverTimer.stop()

                        onClicked: function (mouse) {
                            if (mouse.button === Qt.LeftButton) {
                                windowModel.activate(title);
                                // WindowController.hide();
                            } else if (mouse.button === Qt.RightButton) {
                                windowModel.activateOnly(title);
                            }
                        }
                    }

                    // Top-right control buttons
                    Row {
                        spacing: 6
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 8
                        anchors.rightMargin: 8

                        Button {
                            text: "—"
                            width: 12
                            height: 12
                            onClicked: windowModel.minimize(title)
                        }

                        Button {
                            text: maximized ? "🗗" : "🗖"
                            width: 12
                            height: 12
                            onClicked: {
                                if (maximized)
                                    windowModel.unmaximize(title);
                                else
                                    windowModel.maximize(title);
                            }
                        }

                        Button {
                            text: "✕"
                            width: 12
                            height: 12
                            onClicked: windowModel.closeWindow(title)
                        }
                    }

                    // AppID (optional, subtle)
                    Text {
                        text: title
                        color: "#bbbbbb"
                        font.pixelSize: 12
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 12
                        anchors.bottomMargin: 10
                        elide: Text.ElideRight
                        width: parent.width - 24
                    }

                    // App Icon centered
                    Image {
                        anchors.centerIn: parent
                        source: iconPath
                        width: windowCard.height / 2
                        height: windowCard.height / 2
                        sourceSize.width: windowCard.height / 2
                        sourceSize.height: windowCard.height / 2
                        fillMode: Image.PreserveAspectFit
                    }

                    Timer {
                        id: hoverTimer
                        interval: 150
                        repeat: false
                        onTriggered: windowModel.activate(title)
                    }


                }
            }
        }
    }
}
