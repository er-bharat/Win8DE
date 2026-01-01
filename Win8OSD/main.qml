import QtQuick
import QtQuick.Window

Window {
    id: root
    visible: false
    width: 80
    height: 320
    color: "transparent"

    flags: Qt.FramelessWindowHint
    | Qt.WindowStaysOnTopHint
    | Qt.Tool

    // Provided by your C++ side
    property string mode: osdMode      // "volume" | "brightness" | "mute"
    property int value: osdValue       // 0–100
    property bool muted: osdMuted

    // ================= Background =================
    Rectangle {
        id: osdBg
        width: 80
        height: 320
        color: "#cc000000"   // translucent black
        radius: 0            // Windows 8 sharp edges
        anchors.centerIn: parent

        // ================= Track =================
        Rectangle {
            id: track
            width: 18
            height: parent.height - 80
            color: "#777777"
            radius: 0
            anchors.centerIn: parent

            // ================= Fill =================
            Rectangle {
                id: fill
                width: parent.width
                anchors.bottom: parent.bottom
                height: muted ? 0 : parent.height * value / 100
                radius: 0
                color: mode === "brightness" ? "#ffd600" : "#1e88ff"

                Behavior on height {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            // ================= Knob =================
            Rectangle {
                id: knob
                width: 18
                height: 18
                color: "white"
                radius: 0
                anchors.horizontalCenter: parent.horizontalCenter

                y: muted
                ? parent.height - height
                : parent.height
                - (parent.height * value / 100)
                - height / 2

                Behavior on y {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }

        // ================= Label =================
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            text: muted ? "Muted" : value
            color: "white"
            font.pixelSize: 14
            font.bold: true
        }
    }
}
