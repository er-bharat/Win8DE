import QtQuick
import QtQuick.Window

Window {
    id: root
    width: 4
    height: 4
    visible: false
    color: "#c8150c79"

    property string cornerCommand: ""  // Set from C++
    property bool triggered: false
    property bool hovered: false
    
    Rectangle {
        id: startBtn
        width: parent.width
        height: width * 9 / 16
        
        Image {
            anchors.fill: parent
            source: "start.png"
            fillMode: Image.PreserveAspectCrop
        }
        
    }
    

    // Smooth size animation
    Behavior on width {
        NumberAnimation {
            duration: 50
            easing.type: Easing.Linear
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 50
            easing.type: Easing.Linear
        }
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onEntered: {
            triggered = false   // Reset when cursor enters
            hovered = true
            root.width = 200
            root.height = 113
        }

        onClicked: {
            if (!triggered && cornerCommand !== "") {
                triggered = true
                hotCornerLauncher.launch(cornerCommand)
            }
        }

        onExited: {
            triggered = false   // Allow retrigger after leaving
            hovered = false
            root.width = 4
            root.height = 4
        }
    }
    /* Clock is created ONLY when hovered */
    Loader {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        // anchors.right: parent.right
        active: root.hovered
        asynchronous: true

        sourceComponent: Item {
            width: root.width*(2/3)
            height: root.height

            Column {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    id: start
                    font.pixelSize: 30
                    text: "Start"
                    color: "white"
                }

                Text {
                    id: clockText
                    font.pixelSize: 20
                    font.bold: true
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    id: dateText
                    font.pixelSize: 14
                    color: "#dddddd"
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true

                onTriggered: {
                    const d = new Date()
                    clockText.text = Qt.formatTime(d, "hh:mm AP")
                    dateText.text = Qt.formatDate(d, "ddd, dd MMM yyyy")
                }
            }
        }
    }
}
