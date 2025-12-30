import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Window
import QtQuick.Effects

Window {
    id: root

    property string username: systemUsername
    property string password: ""
    property real hexWidth: AppModel.HexWidth
    property real hexHeight: AppModel.HexHeight
    property real fieldWidth: 500
    property real fieldHeight: 60
    property real fontBig: 22
    property real fontSmall: 10
    property color hexFillColor: "#1b1f2a"
    property color hoveredColor: AppModel.HoveredColor
    property color borderColor: AppModel.BorderColor
    property color borderHoveredColor: AppModel.BorderHoveredColor
    property real borderWidth: AppModel.BorderWidth

    width: Screen.width
    height: Screen.height
    // visible: true
    color: "#222"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    Keys.onPressed: {
        console.log("Key pressed:", event.key);
        event.accepted = true;
    }

    Image {
        id: bg

        anchors.fill: parent
        source: wallpaperPath
        fillMode: Image.PreserveAspectCrop
    }
    MultiEffect {
        anchors.fill: bg
        source: bg
        blurEnabled : true
        blur: 1
        blurMax : 50
        autoPaddingEnabled : true
    }

    Item {
        id: userlogo
        anchors.top: parent.top
        anchors.topMargin: 36
        anchors.horizontalCenter: parent.horizontalCenter
        width: 136
        height: 136

        Item {
            id: avatarBack

            anchors.centerIn: parent

            width: 136
            height: 136


            Shape {
                anchors.fill: parent
                antialiasing: true


                ShapePath {
                    strokeWidth: borderWidth
                    strokeColor: borderColor
                    fillColor: "transparent"
                    fillRule: ShapePath.WindingFill
                    capStyle: ShapePath.FlatCap
                    joinStyle: ShapePath.MiterJoin
                    startX: avatarBack.width / 2
                    startY: 0

                    PathLine { x: avatarBack.width;       y: avatarBack.height * 0.25 }
                    PathLine { x: avatarBack.width;       y: avatarBack.height * 0.75 }
                    PathLine { x: avatarBack.width / 2;   y: avatarBack.height }
                    PathLine { x: 0;                y: avatarBack.height * 0.75 }
                    PathLine { x: 0;                y: avatarBack.height * 0.25 }
                    PathLine { x: avatarBack.width / 2;   y: 0 }
                }
            }
        }
        Image {
            id: avatar

            anchors.centerIn: parent
            fillMode: Image.PreserveAspectFit
            source: userAvatar
            width: 128
            height: 128
            visible: false
        }
        Item {
            id: avatarMask

            anchors.centerIn: parent

            // This item defines its own size (can be overridden by parent)
            width: 128
            height: 128
            layer.enabled: true
            layer.smooth: true

            Shape {
                anchors.fill: parent
                antialiasing: true
                layer.enabled: true
                layer.smooth: true

                ShapePath {

                    fillColor: "white"
                    fillRule: ShapePath.WindingFill
                    capStyle: ShapePath.FlatCap
                    joinStyle: ShapePath.MiterJoin
                    startX: avatarMask.width / 2
                    startY: 0

                    PathLine { x: avatarMask.width;       y: avatarMask.height * 0.25 }
                    PathLine { x: avatarMask.width;       y: avatarMask.height * 0.75 }
                    PathLine { x: avatarMask.width / 2;   y: avatarMask.height }
                    PathLine { x: 0;                y: avatarMask.height * 0.75 }
                    PathLine { x: 0;                y: avatarMask.height * 0.25 }
                    PathLine { x: avatarMask.width / 2;   y: 0 }
                }
            }
        }
        MultiEffect {
            anchors.fill: avatar
            source: avatar
            maskEnabled: true
            maskSource: avatarMask
        }
    }

    Item {
        id: hexClock

        property string currentTime: Qt.formatTime(new Date(), "hh:mm:ss")
        property string currentDate: Qt.formatDate(new Date(), "ddd, MMM d")

        width: hexWidth * 0.8
        height: hexHeight * 0.6
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Screen.height / 54
        anchors.rightMargin: Screen.width / 96

        Shape {
            anchors.fill: parent
            antialiasing: true

            ShapePath {
                strokeWidth: borderWidth / 2
                strokeColor: borderColor
                fillColor: hexFillColor
                fillRule: ShapePath.WindingFill
                capStyle: ShapePath.FlatCap
                joinStyle: ShapePath.MiterJoin
                startX: hexClock.width / 2
                startY: 0

                PathLine {
                    x: hexClock.width
                    y: hexClock.height * 0.25
                }

                PathLine {
                    x: hexClock.width
                    y: hexClock.height * 0.75
                }

                PathLine {
                    x: hexClock.width / 2
                    y: hexClock.height
                }

                PathLine {
                    x: 0
                    y: hexClock.height * 0.75
                }

                PathLine {
                    x: 0
                    y: hexClock.height * 0.25
                }

                PathLine {
                    x: hexClock.width / 2
                    y: 0
                }

            }

        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                hexClock.currentTime = Qt.formatTime(new Date(), "hh:mm:ss");
                hexClock.currentDate = Qt.formatDate(new Date(), "ddd, MMM d");
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
                text: hexClock.currentTime
                font.pointSize: fontSmall * 1.4
                font.weight: Font.Black
                font.family: "Orbitron"
                color: borderHoveredColor
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: hexClock.currentDate
                font.pointSize: fontSmall
                font.family: "Orbitron"
                color: borderHoveredColor
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

        }

    }

    Rectangle {
        id: container

        anchors.fill: parent
        anchors.centerIn: parent
        color: "transparent"

        Column {
            spacing: 30
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: container.height / 3.7
            anchors.leftMargin: container.width / 2 - fieldWidth / 2

            // Username field
            Item {
                id: usernameInput

                width: fieldWidth
                height: fieldHeight

                Shape {
                    anchors.fill: parent
                    antialiasing: true

                    ShapePath {
                        strokeWidth: 3
                        strokeColor: "#FF00FFFF"
                        fillColor: "#1b1f2a"
                        fillRule: ShapePath.WindingFill
                        capStyle: ShapePath.FlatCap
                        joinStyle: ShapePath.MiterJoin
                        startX: usernameInput.height / 2
                        startY: 0

                        PathLine { x: usernameInput.width - usernameInput.height / 2; y: 0 }
                        PathLine { x: usernameInput.width; y: usernameInput.height / 2 }
                        PathLine { x: usernameInput.width - usernameInput.height / 2; y: usernameInput.height }
                        PathLine { x: usernameInput.height / 2; y: usernameInput.height }
                        PathLine { x: 0; y: usernameInput.height / 2 }
                        PathLine { x: usernameInput.height / 2; y: 0 }
                    }
                }

                Item {
                    anchors.fill: parent
                    // anchors.leftMargin: usernameInput.height * 0.6

                    // User Icon
                    Image {
                        id: userIcon
                        source: "peoplew.png"   // put your icon path here
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 25
                        width: 24
                        height: 24
                        fillMode: Image.PreserveAspectFit
                    }
                    TextField {
                        id: usernameField

                        anchors.left: parent.left
                        anchors.leftMargin: 70
                        anchors.fill: parent
                        placeholderText: root.username
                        font.pixelSize: fontBig
                        font.family: "Orbitron"
                        font.weight: Font.Black
                        color: "red"
                        background: null
                        focus: false
                        onTextChanged: root.username = text
                    }
                }
            }

            // Password + Button row
            Row {
                spacing: -fieldHeight / 2

                // Password field
                Item {
                    id: passwordBox

                    width: fieldWidth
                    height: fieldHeight

                    Shape {
                        anchors.fill: parent
                        antialiasing: true

                        ShapePath {
                            strokeWidth: 3
                            strokeColor: "#FF00FFFF"
                            fillColor: "#1b1f2a"
                            fillRule: ShapePath.WindingFill
                            capStyle: ShapePath.FlatCap
                            joinStyle: ShapePath.MiterJoin
                            startX: passwordBox.height / 2
                            startY: 0

                            PathLine { x: passwordBox.width - passwordBox.height / 2; y: 0 }
                            PathLine { x: passwordBox.width; y: passwordBox.height / 2 }
                            PathLine { x: passwordBox.width - passwordBox.height / 2; y: passwordBox.height }
                            PathLine { x: passwordBox.height / 2; y: passwordBox.height }
                            PathLine { x: 0; y: passwordBox.height / 2 }
                            PathLine { x: passwordBox.height / 2; y: 0 }
                        }
                    }

                    Item {
                        anchors.fill: parent

                        // Key Icon
                        Image {
                            id: keyIcon
                            source: "keyw.png"   // put your icon path here
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 25
                            width: 30
                            height: 24
                            fillMode: Image.PreserveAspectFit
                        }
                        TextField {
                            id: passwordField

                            anchors.left: parent.left
                            anchors.leftMargin: 70
                            anchors.fill: parent
                            placeholderText: "Password"
                            echoMode: TextInput.Password
                            font.pixelSize: fontBig
                            font.family: "Orbitron"
                            font.weight: Font.Black
                            color: "red"
                            background: null
                            focus: true
                            Keys.onReturnPressed: {
                                lockManager.authenticate(root.username, root.password);
                            }
                            onTextChanged: root.password = text
                        }
                    }
                }

                // Unlock button
                Item {
                    id: unlockButtonContainer

                    property bool hovered: false

                    width: fieldWidth / 2.5
                    height: fieldHeight

                    Shape {
                        id: hexButtonShape

                        anchors.fill: parent
                        antialiasing: true

                        ShapePath {
                            strokeWidth: 3
                            strokeColor: unlockButtonContainer.hovered ? "red" : "#FF00FFFF"
                            fillColor: unlockButtonContainer.hovered ? "lime green" : "#1b1f2a"
                            fillRule: ShapePath.WindingFill
                            capStyle: ShapePath.FlatCap
                            joinStyle: ShapePath.MiterJoin
                            startX: unlockButtonContainer.height / 2
                            startY: 0

                            PathLine { x: unlockButtonContainer.width - unlockButtonContainer.height / 2; y: 0 }
                            PathLine { x: unlockButtonContainer.width; y: unlockButtonContainer.height / 2 }
                            PathLine { x: unlockButtonContainer.width - unlockButtonContainer.height / 2; y: unlockButtonContainer.height }
                            PathLine { x: unlockButtonContainer.height / 2; y: unlockButtonContainer.height }
                            PathLine { x: unlockButtonContainer.height; y: unlockButtonContainer.height / 2 }
                            PathLine { x: unlockButtonContainer.height / 2; y: 0 }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: fieldHeight + fontSmall
                            text: "Unlock"
                            color: "red"
                            font.family: "Orbitron"
                            font.pixelSize: fontBig
                            font.weight: Font.Black
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: unlockButtonContainer.hovered = true
                        onExited: unlockButtonContainer.hovered = false
                        onClicked: {
                            console.log("Trying to auth as:", root.username, "with password:",);
                            lockManager.authenticate(root.username, root.password);
                        }
                    }
                }
            }
        }
    }

    Connections {
        function onAuthResult(success) {
            if (success) {
                Qt.quit();
            } else {
                console.log("Authentication failed");
                passwordField.text = "";
                passwordField.forceActiveFocus();
            }
        }

        target: lockManager
    }
}
