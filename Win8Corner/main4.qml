import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    id: root
    width: 4
    height: 4
    visible: false
    color: "#28cc3333"

    property string cornerCommand: ""  // Set from C++
    property bool triggered: false

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            triggered = false   // Reset when cursor enters
        }

        onClicked: {
            if (!triggered && cornerCommand !== "") {
                triggered = true
                hotCornerLauncher.launch(cornerCommand)
            }
        }

        onExited: {
            triggered = false   // Allow retrigger after leaving
        }
    }
}
