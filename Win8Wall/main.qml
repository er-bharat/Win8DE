// main.qml
import QtQuick
import QtQuick.Window
import QtQuick.Effects

Window {
    id: root
    visible: false
    width: 800
    height: 600

    // Image {
    //     anchors.fill: parent
    //     source: wallpaperPath
    //     fillMode: Image.PreserveAspectCrop
    // }
    AnimatedImage {
        id: wallImg
        anchors.fill: parent
        source: wallpaperPath
        fillMode: Image.PreserveAspectCrop
        playing: true
        
    }
    
    MultiEffect {
        id: wallBlur
        anchors.fill: parent
        source: wallImg
        blurEnabled : true
        blur: 2
        blurMax : 50
        autoPaddingEnabled : false
        
        Behavior on blur {
            NumberAnimation {
                duration: 200
                easing.type: Easing.Linear
            }
        }
    }
    
    Timer {
        id: waitTimer
        interval: 500
        repeat: false
        running: false
        onTriggered: {
            wallImg.playing = true
            wallBlur.blur = 0
        }
    }
    
    Timer {
        id: waitTimer2
        interval: 500
        repeat: false
        running: false
        onTriggered: {
            wallImg.playing = false
            wallBlur.blur = 2
        }
    }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        
        onEntered: {
            waitTimer.start()
            waitTimer2.stop()
        }
        
        onExited: {
            waitTimer2.start()
            waitTimer.stop()
        }
    }
}
