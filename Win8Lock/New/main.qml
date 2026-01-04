import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    id: root
    width: Screen.width
    height: Screen.height
    // visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    Keys.onPressed: function(event) {
        console.log("Key pressed:", event.key);
        event.accepted = true;
    }
    property string username: systemUsername
    property string password: ""

    // ---- CLOCK UPDATE FUNCTION ----
    function updateClock() {
        var d = new Date()

        // Time like Windows 10: HH:MM
        var hh = d.getHours().toString().padStart(2, "0")
        var mm = d.getMinutes().toString().padStart(2, "0")
        timeLabel.text = hh + ":" + mm

        // Date format: Sunday 16
        var weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        var months = ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"];

        dateLabel.text = weekdays[d.getDay()] + " " +
        months[d.getMonth()] + " " +
        d.getDate();

    }

    // Background rectangle with user and password
    Rectangle {
        id: passwordUi
        anchors.fill : parent
        color: Win8Colors.background
        opacity: 0
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                vkeyboard.hide()
            }
        }

        Rectangle {
            anchors.top: parent.top
            width: passwordUi.width
            height: 50
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    slideDown.start()
                    passwordField.focus = false
                }
            }
        }

        Rectangle {
            id: vkeyshell
            anchors.bottom: box1.bottom
            anchors.left: box1.left
            width: box1.width
            height: box1.height
            color: "transparent"

            VirtualKeyboard {
                id: vkeyboard

                width: box1.width
                height: box1.height
                opacity: 0
            }
        }

        Rectangle {
            id: box1
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: height
            width: root.height* 0.5
            height: width*0.5
            color: "skyblue"

            Row {
                anchors.centerIn: parent
                spacing: 10
                Rectangle {
                    width: box1.height *0.8
                    height: box1.height *0.8
                    color: "transparent"
                    Image {
                        height: box1.height *0.8
                        width: box1.height *0.8
                        source: "peoplew.png"
                    }
                    Image {
                        height: box1.height *0.8
                        width: box1.height *0.8
                        source: userAvatar
                    }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    TextField {
                        id: usernameField
                        width:box1.height *0.9
                        placeholderText: root.username
                        font.pixelSize: 22
                        font.weight: Font.Black
                        color: "red"
                        focus: false
                        onTextChanged: root.username = text

                        onActiveFocusChanged: if (activeFocus) {
                            vkeyboard.currentField = usernameField
                        }
                    }
                    TextField {
                        id: passwordField
                        width: box1.height *0.9
                        placeholderText: "Password"
                        echoMode: TextInput.Password
                        font.pixelSize: 22
                        font.weight: Font.Black
                        color: "red"
                        focus: false
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                lockManager.authenticate(root.username, root.password)
                                event.accepted = true
                            }
                        }

                        onTextChanged: root.password = text

                        onActiveFocusChanged: if (activeFocus) {
                            vkeyboard.currentField = passwordField
                        }
                    }
                    Row {
                        spacing: parent.width-(logi.width+vkey.width)
                        Rectangle {
                            id: logi
                            width: 100
                            height: 50
                            z: -1
                            Text {

                                anchors.centerIn: parent
                                text: "Unlock"
                                color: "red"
                                font.family: "Orbitron"
                                font.pixelSize: 22
                                font.weight: Font.Black
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: lockManager.authenticate(root.username, root.password)
                            }
                        }
                        Rectangle {
                            id: vkey
                            width: 50
                            height: 50
                            z: -1
                            color: "transparent"

                            Image {
                                id: icon
                                source: "vkey.svg"
                                anchors.fill: parent
                                sourceSize: Qt.size(parent.height, parent.height)
                                fillMode: Image.PreserveAspectFit   // recommended for SVG
                                smooth: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (vkeyboard.y >= vkeyshell.height - 5)
                                        vkeyboard.show()
                                        else
                                            vkeyboard.hide()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Top Rectangle that hosts clock and lockscreen wallpaper
    Rectangle {
        id: lockTop
        width: root.width
        height: root.height
        color: "grey"
        y: -root.height
        focus: true

        Image {
            id: bg

            anchors.fill: parent
            source: wallpaperPath
            fillMode: Image.PreserveAspectCrop
        }

        // ---- CLOCK + DATE (BOTTOM LEFT) ----
        Column {
            id: clockContainer
            anchors {
                left: parent.left
                bottom: parent.bottom
                leftMargin: 50
                bottomMargin: 150
            }
            spacing: 2

            Label {
                id: timeLabel
                font.pixelSize: 190
                color: "white"
                font.weight: Font.Thin
                text: ""
            }

            Label {
                id: dateLabel
                font.pixelSize: 60
                color: "white"
                font.weight: Font.Thin
                text: ""
            }
        }
        // Initialize the clock immediately
        Component.onCompleted: {
            updateClock()
            clockTimer.start()
        }

        // Timer for updates
        Timer {
            id: clockTimer
            interval: 1000
            repeat: true
            running: false
            onTriggered: updateClock()
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                slideUp.start()
                passwordField.focus = true
            }
        }
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                slideUp.start()
                passwordField.focus = true
            }
        }
    }

    PropertyAnimation {
        id: slideUp
        target: lockTop
        property: "y"
        to: -root.height
        duration: box1.height *0.9
    }
    PropertyAnimation {
        id: slideDown
        target: lockTop
        property: "y"
        to: 0
        duration: box1.height *0.9
    }

    SequentialAnimation {
        id: showPassAnim

        PauseAnimation {
            duration: 500   // delay in ms
        }

        ParallelAnimation {
            id: showPass
            PropertyAnimation {
                id: showPass1
                target: passwordUi
                property: "opacity"
                to: 1
                duration: 1000
            }
            PropertyAnimation {
                id: showPass2
                target: vkeyboard
                property: "opacity"
                to: 1
                duration: 1000
            }
        }
    }
    ParallelAnimation {
        id: hidePass
        // Duration can be set per animation or globally
        PropertyAnimation {
            target: passwordUi
            property: "opacity"
            to: 0
            duration: 500
        }
        PropertyAnimation {
            target: vkeyboard        // another target
            property: "opacity"
            to: 0
            duration: 500
        }

        onFinished: {
            root.close()   // run after both animations complete
        }
    }

    Connections {
        function onAuthResult(success) {
            if (success) {
                hidePass.start();
                // Qt.quit();
            } else {
                console.log("Authentication failed");
                passwordField.text = "";
                passwordField.forceActiveFocus();
            }
        }

        target: lockManager
    }
    Component.onCompleted: {
        slideDown.start()
        showPassAnim.start()
    }
}
