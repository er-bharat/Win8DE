import QtQuick
import QtQuick.Controls
import Windows 1.0

pragma ComponentBehavior: Bound

ApplicationWindow {
    visible: false
    width: 240
    height: screen.height
    title: "Window Switcher"
    color: "#cc000000"

    WindowModel {
        id: windowModel
    }

    /* ---------- Close strip ---------- */
    Rectangle {
        id : cornerbtn
        width: 4
        height: 4
        anchors.left: parent.left
        anchors.top: parent.top
        z: 10
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    console.log("Left click → hide")
                    WindowController.hide()
                } else if (mouse.button === Qt.RightButton) {
                    console.log("Right click → toggle exclusive")
                    WindowController.toggleExclusive()
                }
            }
        }

    }

    /* ---------- Window list ---------- */
    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 20
        model: windowModel
        spacing: 12
        clip: true
        currentIndex: -1
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            required property bool focused
            required property bool maximized
            required property bool minimized
            required property string appId
            required property string title
            required property string iconPath
            required property int index

            width: list.width
            height: width * 9 / 16
            radius: 0

            color: ListView.isCurrentItem
            ? "#143062"
            : focused ? "#2d6cdf" : "#2a2a2a"

            border.width: focused ? 2 : 1
            border.color: focused ? "#6aa9ff" : "#555"

            /* ---- App ID ---- */
            Text {
                text: appId
                color: "white"
                font.pixelSize: 12
                elide: Text.ElideRight
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 12
                width: parent.width - 48
            }

            /* ---- Mouse handling ---- */
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onEntered: {
                    list.currentIndex = index
                    if (!minimized)
                    windowModel.activate(index)
                }
                onExited: list.currentIndex = -1

                onClicked: function(mouse) {
                    if (mouse.button === Qt.LeftButton) {
                        if (minimized || WindowController.exclusive) {
                            windowModel.activate(index)
                        } else {
                            windowModel.activate(index)
                            WindowController.hide()
                        }
                    } else if (mouse.button === Qt.RightButton) {
                        windowModel.activateOnly(index)
                    }
                }

            }

            /* ---- Window controls ---- */
            Row {
                spacing: 6
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 8

                Button {
                    text: "—"
                    width: 12
                    height: 12
                    onClicked: windowModel.minimize(index)
                }

                Button {
                    text: maximized ? "🗗" : "🗖"
                    width: 12
                    height: 12
                    onClicked: {
                        maximized
                        ? windowModel.unmaximize(index)
                        : windowModel.maximize(index)
                    }
                }

                Button {
                    text: "✕"
                    width: 12
                    height: 12
                    onClicked: windowModel.closeWindow(index)
                }
            }

            /* ---- Window title ---- */
            Text {
                text: title
                color: "#bbbbbb"
                font.pixelSize: 12
                elide: Text.ElideRight
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 12
                width: parent.width - 24
            }

            /* ---- Icon ---- */
            Image {
                anchors.centerIn: parent
                source: iconPath
                width: parent.height / 2
                height: parent.height / 2
                fillMode: Image.PreserveAspectFit
            }
        }
    }

}
