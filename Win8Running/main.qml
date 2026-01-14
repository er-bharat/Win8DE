pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Windows 1.0

ApplicationWindow {
    id: root
    visible: false
    width: 240
    height: screen.height
    title: "Window Switcher"
    color: "#cc000000"

    WindowModel {
        id: windowModel
    }
    function focusIndex() {
        windowModel.reload();
        list.currentIndex = windowModel.indexOfFocused();
        
        if (list.currentIndex >= 0) {
            list.positionViewAtIndex(list.currentIndex, ListView.Contain);
            
        }
    }
    
    onVisibleChanged: {
        if (visible) {
            focusIndex();
        }
    }
    
    // Timer {
    //     interval: 500
    //     repeat: root.visible
    //     running: root.visible
    //     onTriggered:{
    //         WindowController.releaseKeyboardMomentarily()
    //         Qt.callLater(function () {
    //             focusIndex()
    //         })
    //     } 
    // }
    
    
    /* ---------- Close strip ---------- */
    Rectangle {
        id: cornerbtn
        width: 30
        height: width
        anchors.left: parent.left
        anchors.leftMargin: -width/2
        anchors.top: parent.top
        anchors.topMargin: -height/2
        radius: width/2
        z: 10
        color: WindowController.exclusive ? "purple" : "red"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: function (mouse) {
                if (mouse.button === Qt.LeftButton) {
                    console.log("Left click → hide");
                    WindowController.hide();
                } else if (mouse.button === Qt.RightButton) {
                    console.log("Right click → toggle exclusive");
                    WindowController.toggleExclusive();
                }
            }
        }
    }

    /* ---------- Window list ---------- */
    Item {
        width: parent.width
        height: parent.height
        x: root.visible ? 0 : -width
        
        Behavior on x {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
        
        Item {
            id: container
            anchors.fill: parent
            focus: true
            
            Keys.onPressed: function (event) {
                if (list.count === 0)
                    return;
                switch (event.key) {
                    case Qt.Key_Down:
                    case Qt.Key_Tab:
                    case Qt.Key_J:
                        list.currentIndex = (list.currentIndex + 1) % list.count;
                        windowModel.activate(list.currentIndex);
                        event.accepted = true;
                        break;
                    case Qt.Key_Up:
                    case Qt.Key_Backtab:
                    case Qt.Key_K:
                        list.currentIndex = (list.currentIndex - 1 + list.count) % list.count;
                        windowModel.activate(list.currentIndex);
                        event.accepted = true;
                        break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        if (list.currentIndex >= 0) {
                            windowModel.activate(list.currentIndex);
                            if (!WindowController.exclusive)
                                WindowController.hide();
                        }
                        event.accepted = true;
                        break;
                    case Qt.Key_Escape:
                        WindowController.hide();
                        event.accepted = true;
                        break;
                    case Qt.Key_X:
                        if (list.currentIndex >= 0)
                            windowModel.close(list.currentIndex);
                    event.accepted = true;
                    break;
                    case Qt.Key_M:
                        if (list.currentIndex >= 0)
                            windowModel.minimize(list.currentIndex);
                    event.accepted = true;
                    break;
                }
            }
            
            ListView {
                id: list
                // anchors.fill: parent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: startBtn.top
                anchors.margins: 20
                model: windowModel
                spacing: 12
                clip: true
                currentIndex: -1
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: false
                
                delegate: Rectangle {
                    required property bool focused
                    required property bool maximized
                    required property bool minimized
                    required property string appId
                    required property string title
                    required property string iconPath
                    required property int index
                    
                    readonly property bool selected: ListView.isCurrentItem
                    // readonly property bool osFocused: focused && !selected
                    
                    width: list.width
                    height: width * 9 / 16
                    radius: 0
                    
                    color: selected || focused ? Win8Colors.Tile : "#2a2a2a"
                    
                    border.width: selected ? 1 : focused ? 1 : 0
                    border.color: selected /*|| focused*/ ? "#6aa9ff" : "#555"
                    
                    DropArea {
                        anchors.fill: parent
                        
                        onEntered: {
                            list.currentIndex = index;
                            if (!minimized)
                                windowModel.activate(index);
                        }
                    }
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
                            list.currentIndex = index;
                            if (!minimized)
                                windowModel.activate(index);
                        }
                        // onExited: list.currentIndex = -1
                        
                        onClicked: function (mouse) {
                            if (mouse.button === Qt.LeftButton) {
                                if (minimized || WindowController.exclusive) {
                                    windowModel.activate(index);
                                } else {
                                    windowModel.activate(index);
                                    WindowController.hide();
                                }
                            } else if (mouse.button === Qt.RightButton) {
                                windowModel.activateOnly(index);
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
                            text: maximized ? "o" : "O"
                            width: 12
                            height: 12
                            onClicked: {
                                maximized ? windowModel.unmaximize(index) : windowModel.maximize(index);
                            }
                        }
                        
                        Button {
                            text: "✕"
                            width: 12
                            height: 12
                            onClicked: windowModel.close(index)
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
            Rectangle {
                id: startBtn
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.margins: 20
                width: list.width
                height: width * 9 / 16
                
                Image {
                    anchors.fill: parent
                    source: "start.png"
                    fillMode: Image.PreserveAspectCrop
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Launcher.launchDetached("Win8Start")
                        WindowController.hide()
                    }
                }
            }
            
        }
    }
    
}
