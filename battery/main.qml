import QtQuick
import QtQuick.Window
import QtMultimedia

Window {
    id: rootWindow
    visible: false         // Show via C++
    width: 400
    height: 200
    title: "LayerShell Overlay Example"
    
    SoundEffect {
        id: playSound
        source: "qrc:/alert.wav"
    }
    Component.onCompleted: {
        playSound.play()
    }
    Rectangle {
        anchors.fill: parent
        color: "black"
        
        Row {
            anchors.fill: parent
            spacing: 0
            
            Item {
                width: parent.width/3
                height: parent.height
                
                Image {
                    anchors.centerIn: parent
                    anchors.fill: parent
                    anchors.margins: 20
                    id: eventIcon
                    source: {
                        switch (eventType) {
                            case "charging": return "qrc:/electric.svg";
                            case "discharging": return "qrc:/electricx.svg";
                            case "low": return "qrc:/electricx.svg";
                            case "full": return "qrc:/electric.svg";
                            case "plugged": return "qrc:/electric.svg";
                            case "unplugged": return "qrc:/electricx.svg";
                            default: return "";
                        } 
                    }
                    fillMode: Image.PreserveAspectFit
                    visible: source !== ""
                }
            }
            
            Item {
                width: parent.width*2/3
                height: parent.height
                
                Column {
                    anchors.centerIn: parent
                    width: parent.width
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: eventType
                        color: "white"
                        font.pixelSize: 40
                        font.weight: 800
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: eventValue + "%"
                        color: "white"
                        font.pixelSize: 40
                        font.weight: 800
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}
