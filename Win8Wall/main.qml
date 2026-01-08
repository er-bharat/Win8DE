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
        anchors.fill: parent
        source: wallpaperPath
        fillMode: Image.PreserveAspectCrop
        playing: true
        
    }
}
