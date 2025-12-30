import QtQuick
import QtQuick.Controls

Item {
    id: vk
    visible: true
    y: parent ? parent.height-height : 0

    property var currentField: null
    property bool shiftOn: false
    property string mode: "letters"   // "letters" or "numbers"

    property color keyColor: "#353944"
    property color keyTextColor: "white"
    property color bgColor: "#20222a"

    // ----- KEY WIDTH UNITS -----
    property int keyUnits: 12                     // total width units of a row
    property real keyUnitWidth: width / (keyUnits+(lettersLayout.spacing/2))  // 1 unit = rowWidth / 12

    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

    function show() { y = parent.height - height }
    function hide() { y = parent.height }

    Rectangle {
        anchors.fill: parent
        color: bgColor
    }

    Column {
        anchors.centerIn: parent
        spacing: 4

        // ---------------- LETTERS MODE ----------------
        Column {
            id: lettersLayout
            visible: vk.mode === "letters"
            spacing: 4

            Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: 4; Repeater { model: ["q","w","e","r","t","y","u","i","o","p"]; delegate: keyDelegate } }
            Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: 4; Repeater { model: ["a","s","d","f","g","h","j","k","l"]; delegate: keyDelegate } }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                Button {
                    focusPolicy: Qt.NoFocus
                    text: vk.shiftOn ? "SHIFT ↑" : "shift"
                    width: keyUnitWidth * 2
                    height: vk.height/5
                    onClicked: vk.shiftOn = !vk.shiftOn
                }

                Repeater { model: ["z","x","c","v","b","n","m"]; delegate: keyDelegate }

                Button {
                    focusPolicy: Qt.NoFocus
                    text: "⌫"
                    width: keyUnitWidth * 2
                    height: vk.height/5
                    onClicked: {
                        if (!vk.currentField) return
                            let pos = vk.currentField.cursorPosition
                            if (pos > 0) vk.currentField.remove(pos-1,pos)
                    }
                }
            }

            Row {
                spacing: 4
                anchors.horizontalCenter: parent.horizontalCenter
                Button {
                    focusPolicy: Qt.NoFocus
                    text: "123"
                    width: keyUnitWidth * 2
                    height: vk.height/5
                    onClicked: vk.mode = "numbers"
                }

                Button {
                    focusPolicy: Qt.NoFocus
                    text: "Space"
                    width: keyUnitWidth * 7
                    height: vk.height/5
                    onClicked: if (vk.currentField) vk.currentField.insert(vk.currentField.cursorPosition," ")
                }

                Button {
                    focusPolicy: Qt.NoFocus
                    text: "Enter"
                    width: keyUnitWidth * 2.5
                    height: vk.height/5
                    onClicked: if (vk.currentField) vk.currentField.insert(vk.currentField.cursorPosition,"\n")
                }
            }
        }

        // ---------------- NUMBERS + SYMBOLS MODE ----------------
        Column {
            id: numbersLayout
            visible: vk.mode === "numbers"
            spacing: 4

            Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: 4; Repeater { model: ["1","2","3","4","5","6","7","8","9","0"]; delegate: keyDelegate } }
            Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: 4; Repeater { model: ["-","/",";",":","(",")","$","&","@"]; delegate: keyDelegate } }

            Row {
                spacing: 4
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater { model: ["!","?",".",",","'","\"","%","*","+","="]; delegate: keyDelegate }

                Button {
                    focusPolicy: Qt.NoFocus
                    text: "⌫"
                    width: keyUnitWidth * 2
                    height: vk.height/5
                    onClicked: {
                        if (!vk.currentField) return
                            let pos = vk.currentField.cursorPosition
                            if (pos > 0) vk.currentField.remove(pos-1,pos)
                    }
                }
            }

            Row {
                spacing: 4
                anchors.horizontalCenter: parent.horizontalCenter
                Button {
                    focusPolicy: Qt.NoFocus
                    text: "ABC"
                    width: keyUnitWidth * 2
                    height: vk.height/5
                    onClicked: vk.mode = "letters"
                }

                Button {
                    focusPolicy: Qt.NoFocus
                    text: "Space"
                    width: keyUnitWidth * 7
                    height: vk.height/5
                    onClicked: if (vk.currentField) vk.currentField.insert(vk.currentField.cursorPosition," ")
                }

                Button {
                    focusPolicy: Qt.NoFocus
                    text: "Enter"
                    width: keyUnitWidth * 2.5
                    height: vk.height/5
                    onClicked: if (vk.currentField) vk.currentField.insert(vk.currentField.cursorPosition,"\n")
                }
            }
        }
    }

    // ================== KEY DELEGATE ======================
    Component {
        id: keyDelegate
        Button {
            focusPolicy: Qt.NoFocus
            width: keyUnitWidth
            height: vk.height/5

            text: (vk.shiftOn && vk.mode === "letters")
            ? modelData.toUpperCase()
            : (modelData === "&" ? "&&" : modelData)

            onClicked: {
                if (!vk.currentField) return
                    let charText = (vk.shiftOn && vk.mode === "letters") ? modelData.toUpperCase() : modelData
                    vk.currentField.insert(vk.currentField.cursorPosition,charText)
            }
        }
    }
}
