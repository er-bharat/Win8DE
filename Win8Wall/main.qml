// main.qml
import QtQuick
import QtQuick.Window
import QtQuick.Controls

Window {
    id: root
    visible: false
    width: 800
    height: 600

    Image {
        anchors.fill: parent
        source: wallpaperPath
        fillMode: Image.PreserveAspectCrop
    }
}
