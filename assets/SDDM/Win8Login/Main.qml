/***************************************************************************
* Copyright (c) 2013 Abdurrahman AVCI <abdurrahmanavci@gmail.com>
*
* Permission is hereby granted, free of charge, to any person
* obtaining a copy of this software and associated documentation
* files (the "Software"), to deal in the Software without restriction,
* including without limitation the rights to use, copy, modify, merge,
* publish, distribute, sublicense, and/or sell copies of the Software,
* and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included
* in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
* OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
* OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
* ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
* OR OTHER DEALINGS IN THE SOFTWARE.
*
***************************************************************************/

import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Shapes
import SddmComponents
import QtQuick.Effects

Rectangle {
    id: container

    property int sessionIndex: session.index
    property real hexWidth: 200
    property real hexHeight: 220
    property real fieldWidth: 500
    property real fieldHeight: 60
    property real fontBig: 22
    property real fontSmall: 10
    property color hexFillColor: "#1b1f2a"
    property color hoveredColor: "#d900ff00"
    property color borderColor: "#FF00FFFF"
    property color borderHoveredColor: "red"
    property real borderWidth: 4

    width: 1920
    height: 1080
    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true
    Component.onCompleted: {
        if (name.text == "")
            name.focus = true;
        else
            password.focus = true;
    }

    TextConstants {
        id: textConstants
    }

    Connections {
        target: sddm
        onLoginSucceeded: {
            errorMessage.color = "steelblue";
            errorMessage.text = textConstants.loginSucceeded;
        }
        onLoginFailed: {
            password.text = "";
            errorMessage.color = "red";
            errorMessage.text = textConstants.loginFailed;
        }
        onInformationMessage: {
            errorMessage.color = "red";
            errorMessage.text = message;
        }
    }

    Image {
        id : bg
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        onStatusChanged: {
            if (status == Image.Error && source != config.defaultBackground)
                source = config.defaultBackground;

        }
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
            source: "file:///var/lib/AccountsService/icons/" + name.text
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

    //clock
    Item {
        id: hexClock

        property string currentTime: Qt.formatTime(new Date(), "hh:mm:ss")
        property string currentDate: Qt.formatDate(new Date(), "ddd, MMM d")


        width: hexWidth * 0.8
        height: hexHeight * 0.6
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: container.height / 54
        anchors.rightMargin: container.width / 96

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

                PathLine { x: hexClock.width;    y: hexClock.height * 0.25 }
                PathLine { x: hexClock.width;    y: hexClock.height * 0.75 }
                PathLine { x: hexClock.width / 2; y: hexClock.height }
                PathLine { x: 0; y: hexClock.height * 0.75 }
                PathLine { x: 0; y: hexClock.height * 0.25 }
                PathLine { x: hexClock.width / 2; y: 0 }
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

    //DE chooser
    Item {
        id: sessionInput

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: (hexHeight * 0.6) + (container.height / 54) * 2
        anchors.rightMargin: container.width / 96
        width: hexWidth * 0.8 // ~500
        height: fieldHeight // ~60


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
            height: 20
            font.pixelSize: fontSmall * 1.4
            color: "grey"             // This affects text color
            // arrowIcon: "angle-down.png"      // Make sure this file exists in your project
            model: sessionModel              // Your data model
            index: sessionModel.lastIndex    // Sets initial selected index
            KeyNavigation.backtab: password  // Navigates to password field on Shift+Tab
            // KeyNavigation.tab: layoutBox     // Navigates to layoutBox on Tab
        }

    }

    //login form
    Rectangle {
        id: loginForm
        //visible: primaryScreen

        anchors.fill: parent
        color: "transparent"

        Column {

            id: mainColumn

            anchors.top: parent.top
            anchors.topMargin: container.height / 3.7
            anchors.left: parent.left
            anchors.leftMargin: container.width / 2 - fieldWidth / 2
            width: 600
            spacing: 30

            //Username
            Column {

                width: parent.width
                spacing: 4

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

                    TextInput {
                        id: name

                        anchors.left: parent.left
                        anchors.leftMargin: 70
                        anchors.horizontalCenter: usernameInput.horizontalCenter
                        anchors.verticalCenter: usernameInput.verticalCenter
                        verticalAlignment: TextInput.AlignVCenter
                        width: 450
                        height: 50
                        text: userModel.lastUser
                        font.pixelSize: fontBig
                        font.family: "Orbitron"
                        font.weight: Font.Black
                        color: "red"
                        KeyNavigation.backtab: reboo
                        KeyNavigation.tab: password
                        Keys.onPressed: {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                sddm.login(name.text, password.text, sessionIndex);
                                event.accepted = true;
                            }
                        }
                    }
                }
            }

            //Password
            Column {


                width: parent.width
                spacing: 4

                Row {
                    spacing: -logi.height / 2


                    Item {
                        id: passwordInput

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
                                startX: passwordInput.height / 2
                                startY: 0

                                PathLine { x: passwordInput.width - passwordInput.height / 2; y: 0 }
                                PathLine { x: passwordInput.width; y: passwordInput.height / 2 }
                                PathLine { x: passwordInput.width - passwordInput.height / 2; y: passwordInput.height }
                                PathLine { x: passwordInput.height / 2; y: passwordInput.height }
                                PathLine { x: 0; y: passwordInput.height / 2 }
                                PathLine { x: passwordInput.height / 2; y: 0 }
                            }
                        }

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
                            id: password

                            anchors.left: parent.left
                            anchors.leftMargin: 70
                            anchors.horizontalCenter: passwordInput.horizontalCenter
                            anchors.verticalCenter: passwordInput.verticalCenter
                            verticalAlignment: TextInput.AlignVCenter
                            width: parent.width - 50
                            height: 50
                            font.pixelSize: fontBig
                            font.weight: Font.Black
                            echoMode: TextInput.Password
                            placeholderText: "Password"
                            placeholderTextColor: "lightgray"
                            color: "red"
                            background: Rectangle {
                                color: "transparent"
                                border.width: 0
                            }
                            KeyNavigation.backtab: name
                            KeyNavigation.tab: session
                            Keys.onPressed: {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    sddm.login(name.text, password.text, sessionIndex);
                                    event.accepted = true;
                                }
                            }
                        }
                    }

                    //Login button
                    Item {
                        id: logi

                        property bool hovered: false

                        width: fieldWidth / 2.5
                        height: fieldHeight

                        Shape {
                            anchors.fill: parent
                            antialiasing: true

                            ShapePath {
                                strokeWidth: 3
                                strokeColor: "#FF00FFFF"
                                fillColor: logi.hovered ? "lime green" : "#1b1f2a"
                                fillRule: ShapePath.WindingFill
                                capStyle: ShapePath.FlatCap
                                joinStyle: ShapePath.MiterJoin
                                startX: logi.height / 2
                                startY: 0

                                PathLine { x: logi.width - logi.height / 2; y: 0 }
                                PathLine { x: logi.width; y: logi.height / 2 }
                                PathLine { x: logi.width - logi.height / 2; y: logi.height }
                                PathLine { x: logi.height / 2; y: logi.height }
                                PathLine { x: logi.height; y: logi.height / 2 }
                                PathLine { x: logi.height / 2; y: 0 }
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: fieldHeight + fontSmall
                                text: "Login"
                                color: "red"
                                font.family: "Orbitron"
                                font.pixelSize: fontBig
                                font.weight: Font.Black
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: logi.hovered = true
                                onExited: logi.hovered = false
                                onClicked: sddm.login(name.text, password.text, sessionIndex)
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width

                Text {
                    id: errorMessage

                    anchors.horizontalCenter: parent.horizontalCenter
                    text: textConstants.prompt
                    font.pixelSize: 10
                }
            }
        }

        //Power buttons
        Row {
            spacing: 4
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: (container.height / 54) * 2

            Item {
                id: reboo

                property bool hovered: false


                width: fieldWidth / 3
                height: fieldHeight

                Shape {
                    anchors.fill: parent
                    antialiasing: true

                    ShapePath {
                        strokeWidth: 3
                        strokeColor: "#FF00FFFF"
                        fillColor: reboo.hovered ? "lime green" : "#1b1f2a"
                        fillRule: ShapePath.WindingFill
                        capStyle: ShapePath.FlatCap
                        joinStyle: ShapePath.MiterJoin
                        startX: reboo.height / 2
                        startY: 0

                        PathLine { x: reboo.width - reboo.height / 2; y: 0 }
                        PathLine { x: reboo.width; y: reboo.height / 2 }
                        PathLine { x: reboo.width - reboo.height / 2; y: reboo.height }
                        PathLine { x: reboo.height / 2; y: reboo.height }
                        PathLine { x: 0; y: reboo.height / 2 }
                        PathLine { x: reboo.height / 2; y: 0 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Reboot"
                        color: "red"
                        font.family: "Orbitron"
                        font.pixelSize: fontBig
                        font.weight: Font.Black
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: reboo.hovered = true
                        onExited: reboo.hovered = false
                        onClicked: sddm.reboot()
                    }
                }
            }

            Item {
                id: shutd

                property bool hovered: false

                width: fieldWidth / 3
                height: fieldHeight

                Shape {
                    anchors.fill: parent
                    antialiasing: true

                    ShapePath {
                        strokeWidth: 3
                        strokeColor: "#FF00FFFF"
                        fillColor: shutd.hovered ? "lime green" : "#1b1f2a"
                        fillRule: ShapePath.WindingFill
                        capStyle: ShapePath.FlatCap
                        joinStyle: ShapePath.MiterJoin
                        startX: shutd.height / 2
                        startY: 0

                        PathLine { x: shutd.width - shutd.height / 2; y: 0 }
                        PathLine { x: shutd.width; y: shutd.height / 2 }
                        PathLine { x: shutd.width - shutd.height / 2; y: shutd.height }
                        PathLine { x: shutd.height / 2; y: shutd.height }
                        PathLine { x: 0; y: shutd.height / 2 }
                        PathLine { x: shutd.height / 2; y: 0 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Shutdown"
                        color: "red"
                        font.family: "Orbitron"
                        font.pixelSize: fontBig
                        font.weight: Font.Black
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: shutd.hovered = true
                        onExited: shutd.hovered = false
                        onClicked: sddm.powerOff()
                    }
                }
            }
        }
    }
}
