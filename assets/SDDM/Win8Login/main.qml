import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Shapes
import SddmComponents
import QtQuick.Effects

Rectangle {
    id: container
    property int sessionIndex: session.index
    width: screen.width
    height: screen.height

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

    Component.onCompleted: {
        slideDown.start()
        showPassAnim.start()
        // if (name.text == "")
        //     name.focus = true;
        // else
        //     password.focus = true;

    }

    TextConstants {
        id: textConstants
    }
    Connections {
        target: sddm

        function onLoginSucceeded() {
            errorMessage.color = "steelblue";
            errorMessage.text = textConstants.loginSucceeded;
        }

        function onLoginFailed() {
            password.text = "";
            errorMessage.color = "red";
            errorMessage.text = textConstants.loginFailed;
        }

        function onInformationMessage(message) {
            errorMessage.color = "red";
            errorMessage.text = message;
        }
    }


    Rectangle {
        id: passwordUi
        anchors.fill : parent
        color: "teal"
        opacity: 1

        Rectangle {
            anchors.top: parent.top
            width: passwordUi.width
            height: 50
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    slideDown.start()
                    password.focus = false
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
            // anchors.centerIn: parent
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: height
            width: passwordUi.height* 0.5
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
                        source: "file:///var/lib/AccountsService/icons/" + name.text
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    TextField {
                        id: name
                        width:box1.height *0.9
                        text: userModel.lastUser
                        placeholderText: userModel.lastUser
                        font.pixelSize: 22
                        // font.family: "Orbitron"
                        font.weight: Font.Black
                        color: "red"
                        focus: false
                        onActiveFocusChanged: if (activeFocus) {
                            vkeyboard.currentField = name
                            // vkeyboard.hide()
                        }
                    }
                    TextField {
                        id: password
                        width: box1.height *0.9
                        placeholderText: "Password"
                        echoMode: TextInput.Password
                        font.pixelSize: 22
                        // font.family: "Orbitron"
                        font.weight: Font.Black
                        color: "red"
                        // background: null
                        focus: false
                        Keys.onPressed: {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                sddm.login(name.text, password.text, sessionIndex);
                                event.accepted = true;
                            }
                        }
                        onActiveFocusChanged: if (activeFocus) {
                            vkeyboard.currentField = password
                            // vkeyboard.hide()
                        }

                        onTextChanged: root.password = text
                    }
                    //DE chooser
                    Item {
                        id: sessionInput
                        width: box1.height *0.9
                        height: password.height


                        Rectangle {
                            anchors.fill: parent
                            border.width: 3
                            border.color: "#FF00FFFF"
                            color: "#1b1f2a"
                        }

                        ComboBox {
                            id: session
                            anchors.fill: parent
                            anchors.margins: 5
                            width: parent.width
                            height: password.height
                            font.pixelSize: 22
                            color: "white"
                            arrowIcon: "angle-down.png"
                            model: sessionModel
                            index: sessionModel.lastIndex
                            KeyNavigation.backtab: password
                            KeyNavigation.tab: logi
                        }

                    }
                    Text {
                        id: errorMessage

                        anchors.horizontalCenter: parent.horizontalCenter
                        text: textConstants.prompt
                        font.pixelSize: 10
                    }
                    Row {
                        spacing: parent.width-(logi.width+vkey.width)
                        z: -1
                        Rectangle {
                            id: logi
                            width: 100
                            height: 50
                            KeyNavigation.backtab: name
                            Text {

                                anchors.centerIn: parent
                                text: "Login"
                                color: "red"
                                font.family: "Orbitron"
                                font.pixelSize: 22
                                font.weight: Font.Black
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: sddm.login(name.text, password.text, sessionIndex)
                            }
                        }
                        Rectangle {
                            id: vkey
                            width: 50
                            height: 50
                            z: -1
                            color: "transparent"
                            // Text {
                            //
                            //     anchors.centerIn: parent
                            //     text: "vkey"
                            //     color: "red"
                            //     font.family: "Orbitron"
                            //     font.pixelSize: 22
                            //     font.weight: Font.Black
                            // }
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
    // Top Rectangle that hosts clock and lockcontainer wallpaper
    Rectangle {
        id: lockTop
        width: container.width
        height: container.height
        color: "grey"
        y: -container.height
        focus: true

        Image {
            id: bg

            anchors.fill: parent
            source: config.background
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
                password.focus = true
            }
        }
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                slideUp.start()
                password.focus = true
            }
        }
    }


    PropertyAnimation {
        id: slideUp
        target: lockTop
        property: "y"
        to: -container.height
        duration: 200
    }
    PropertyAnimation {
        id: slideDown
        target: lockTop
        property: "y"
        to: 0
        duration: 200
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

        // onFinished: {
        //     root.close()   // run after both animations complete
        // }
    }

    Rectangle {
        id: powerbtn
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 10
        width: 50
        height: 50
        color:"grey"

        Image {
            anchors.centerIn: parent
            source: "system-shutdown.svg"
            sourceSize: Qt.size(parent.width*0.9, parent.width*0.9)
        }

        // Text {
        //     anchors.centerIn: parent
        //     text: "Shutdown"
        //     color: "red"
        //     font.family: "Orbitron"
        //     font.pixelSize: 16
        //     font.weight: Font.Black
        // }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sddm.powerOff()
        }
    }

}
