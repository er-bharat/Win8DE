// main.qml
import QtQuick
import QtQuick.Window

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
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        
        onEntered: {
            wallImg.playing = true
        }
        
        onExited: {
            wallImg.playing = false
        }
    }
}
