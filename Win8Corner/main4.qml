import QtQuick
import QtQuick.Window

Window {
    id: root
    width: 4
    height: 4
    visible: false
    color: "transparent"

    property string cornerCommand: ""  // Set from C++
    property bool triggered: false
    property bool hovered: false
    
    Rectangle {
        id: indicator
        x: width/2
        y: height/2
        width: parent.width
        height: width
        color: "red" 
        opacity: 0
        radius: width/2
        
        Behavior on opacity {
            NumberAnimation {
                duration: 50
                easing.type: Easing.Linear
            }
        }
    }
    
    
    // Smooth size animation
    Behavior on width {
        NumberAnimation {
            duration: 150
            easing.type: Easing.Linear
        }
    }
    
    Behavior on height {
        NumberAnimation {
            duration: 150
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
            root.width = 40
            root.height = 40
            indicator.opacity = 1
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
            indicator.opacity = 0
        }
    }
}
